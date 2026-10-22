defmodule Joblite.JobBoards.SyncTest do
  use Joblite.DataCase, async: true

  alias Joblite.JobBoards
  alias Joblite.JobBoards.{Listing, Sync}

  setup do
    {:ok, jobicy} = JobBoards.get_source_by_slug("jobicy")
    {:ok, remote_ok} = JobBoards.get_source_by_slug("remote-ok")
    {:ok, remotive} = JobBoards.get_source_by_slug("remotive")
    {:ok, himalayas} = JobBoards.get_source_by_slug("himalayas")

    %{jobicy: jobicy, remote_ok: remote_ok, remotive: remotive, himalayas: himalayas}
  end

  defp jobicy_payload(jobs) do
    {:ok, %{"jobs" => jobs}}
  end

  defp job(job_id, overrides \\ %{}) do
    Map.merge(
      %{
        "id" => job_id,
        "jobTitle" => "Elixir Engineer",
        "url" => "https://jobicy.com/jobs/#{job_id}",
        "companyName" => "Acme",
        "jobGeo" => "Anywhere",
        "jobIndustry" => ["Software Engineering"],
        "pubDate" => "2026-10-20T10:00:00Z"
      },
      overrides
    )
  end

  describe "permission enforcement" do
    test "a directory only source is never imported", %{remotive: remotive} do
      assert {:error, {:not_permitted, :directory_only}} = Sync.sync(remotive)
    end

    test "a source with a pending permission is never imported", %{himalayas: himalayas} do
      assert {:error, {:not_permitted, :permission_pending}} = Sync.sync(himalayas)
    end

    test "the transport is not called for a source that may not be imported", %{
      remotive: remotive
    } do
      transport = fn _url -> flunk("the transport must not be called") end

      assert {:error, {:not_permitted, :directory_only}} =
               Sync.sync(remotive, transport: transport)
    end
  end

  describe "interval enforcement" do
    test "a first pass may run", %{jobicy: jobicy} do
      transport = fn _url -> jobicy_payload([job("1")]) end

      assert {:ok, result} = Sync.sync(jobicy, transport: transport)
      assert result.inserted == 1
    end

    test "a second pass inside the permitted interval is refused", %{jobicy: jobicy} do
      transport = fn _url -> jobicy_payload([job("1")]) end

      assert {:ok, _result} = Sync.sync(jobicy, transport: transport)
      assert {:error, {:sync_too_soon, _elapsed, 60}} = Sync.sync(jobicy, transport: transport)
    end

    test "a pass after the permitted interval may run again", %{jobicy: jobicy} do
      transport = fn _url -> jobicy_payload([job("1")]) end

      assert {:ok, _result} = Sync.sync(jobicy, transport: transport)

      later = DateTime.add(DateTime.utc_now(), 61, :minute)
      assert {:ok, result} = Sync.sync(jobicy, transport: transport, now: later)
      assert result.updated == 1
    end
  end

  describe "imported listings" do
    test "a permitted pass stores the listings with the source attribution", %{jobicy: jobicy} do
      transport = fn _url -> jobicy_payload([job("1"), job("2")]) end

      assert {:ok, result} = Sync.sync(jobicy, transport: transport)
      assert result.inserted == 2
      assert result.expired == 0

      listings = Repo.all(Listing)
      assert length(listings) == 2
      assert Enum.all?(listings, &(&1.attribution == "Jobicy"))
      assert Enum.all?(listings, &(&1.canonical_url =~ "jobicy.com"))
    end

    test "a repeated listing is updated instead of stored twice", %{jobicy: jobicy} do
      transport = fn _url -> jobicy_payload([job("1")]) end

      assert {:ok, %{inserted: 1}} = Sync.sync(jobicy, transport: transport)

      later = DateTime.add(DateTime.utc_now(), 61, :minute)

      assert {:ok, %{inserted: 0, updated: 1}} =
               Sync.sync(jobicy, transport: transport, now: later)

      assert Repo.aggregate(Listing, :count) == 1
    end

    test "a listing that disappeared upstream is expired and not deleted", %{jobicy: jobicy} do
      transport = fn _url -> jobicy_payload([job("1"), job("2")]) end
      assert {:ok, _result} = Sync.sync(jobicy, transport: transport)

      fewer = fn _url -> jobicy_payload([job("1")]) end
      later = DateTime.add(DateTime.utc_now(), 61, :minute)

      assert {:ok, result} = Sync.sync(jobicy, transport: fewer, now: later)
      assert result.expired == 1

      expired = Repo.get_by(Listing, external_id: "2")
      assert expired.status == :expired
      assert expired.expired_at
    end

    test "a listing without a canonical URL is skipped", %{jobicy: jobicy} do
      transport = fn _url ->
        jobicy_payload([job("1", %{"url" => ""})])
      end

      assert {:ok, result} = Sync.sync(jobicy, transport: transport)
      assert result.inserted == 0
      assert result.skipped == 1
      assert Repo.aggregate(Listing, :count) == 0
    end

    test "a malformed entry is dropped before it reaches the database", %{jobicy: jobicy} do
      transport = fn _url ->
        jobicy_payload([job("1", %{"jobTitle" => nil})])
      end

      assert {:ok, result} = Sync.sync(jobicy, transport: transport)
      assert result.inserted == 0
      assert result.skipped == 0
      assert Repo.aggregate(Listing, :count) == 0
    end

    test "the source health is recorded after a pass", %{jobicy: jobicy} do
      transport = fn _url -> jobicy_payload([job("1")]) end

      assert {:ok, _result} = Sync.sync(jobicy, transport: transport)

      {:ok, refreshed} = JobBoards.get_source(jobicy.id)
      assert refreshed.health_status == :healthy
      assert refreshed.last_synced_at
    end

    test "a failing pass marks the source as degraded", %{jobicy: jobicy} do
      transport = fn _url -> {:error, :timeout} end

      assert {:error, :timeout} = Sync.sync(jobicy, transport: transport)

      {:ok, refreshed} = JobBoards.get_source(jobicy.id)
      assert refreshed.health_status == :degraded
    end
  end

  describe "adapters" do
    test "the remote ok adapter keeps the canonical URL and the source attribution", %{
      remote_ok: remote_ok
    } do
      transport = fn _url ->
        {:ok,
         [
           %{
             "id" => "abc",
             "position" => "Backend Engineer",
             "url" => "https://remoteok.com/jobs/abc",
             "company" => "Globex",
             "location" => "Worldwide",
             "tags" => ["Engineering"],
             "date" => "2026-10-20T10:00:00Z"
           }
         ]}
      end

      assert {:ok, result} = Sync.sync(remote_ok, transport: transport)
      assert result.inserted == 1

      listing = Repo.get_by(Listing, external_id: "abc")
      assert listing.canonical_url == "https://remoteok.com/jobs/abc"
      assert listing.attribution == "Remote OK"
      assert listing.remote_eligibility == "worldwide"
    end

    test "an approved adapter exists for every permitted source", %{
      jobicy: jobicy,
      remote_ok: remote_ok,
      remotive: remotive
    } do
      assert {:ok, Joblite.JobBoards.Sync.Jobicy} = Sync.adapter_for(jobicy)
      assert {:ok, Joblite.JobBoards.Sync.RemoteOk} = Sync.adapter_for(remote_ok)
      assert {:error, {:no_approved_adapter, "remotive"}} = Sync.adapter_for(remotive)
    end
  end
end
