defmodule Joblite.JobBoards.Sync do
  @moduledoc """
  Import orchestration for permitted job board sources.

  A synchronization pass is refused unless the source mode allows
  aggregation, the source's permitted interval has elapsed and an approved
  adapter is registered for it. Imported listings are deduplicated on the
  source's own identifier and on the canonical listing URL, and a listing
  that disappeared upstream is expired instead of deleted.
  """

  import Ecto.Query, warn: false

  alias Joblite.JobBoards.{Listing, Source, SourceMode}
  alias Joblite.JobBoards.Sync.Entry
  alias Joblite.Repo

  @adapters %{
    "jobicy" => Joblite.JobBoards.Sync.Jobicy,
    "remote-ok" => Joblite.JobBoards.Sync.RemoteOk
  }

  @doc """
  Runs one synchronization pass for a source.

  Returns `{:ok, %{inserted: n, updated: n, duplicates: n, expired: n}}` or a
  tagged error. The source is never imported when its mode forbids
  aggregation, whatever the adapter returns.
  """
  @spec sync(Source.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def sync(%Source{} = source, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    # The stored row is read again so the interval is measured against the
    # last pass that actually ran, not against the caller's copy of the source.
    case Repo.get(Source, source.id) do
      nil -> {:error, :unknown_source}
      current -> run(current, now, opts)
    end
  end

  defp run(source, now, opts) do
    with :ok <- ensure_aggregate_allowed(source),
         :ok <- ensure_interval_elapsed(source, now),
         {:ok, adapter} <- adapter_for(source),
         {:ok, listings} <- fetch(source, adapter, opts, now) do
      {inserted, updated, duplicates, skipped} = store(source, listings, now)
      expired = expire(source, listings, now)
      record_health(source, now, :healthy, nil)

      {:ok,
       %{
         inserted: inserted,
         updated: updated,
         duplicates: duplicates,
         skipped: skipped,
         expired: expired
       }}
    end
  end

  @doc "The adapters approved for aggregation. Only permitted sources appear here."
  @spec approved_adapters() :: %{String.t() => module()}
  def approved_adapters, do: @adapters

  @doc "The adapter registered for a source, or an error when none is approved."
  @spec adapter_for(Source.t()) :: {:ok, module()} | {:error, term()}
  def adapter_for(%Source{slug: slug}) do
    case Map.fetch(@adapters, slug) do
      {:ok, adapter} -> {:ok, adapter}
      :error -> {:error, {:no_approved_adapter, slug}}
    end
  end

  @doc "Whether a source may be imported at all."
  @spec importable?(Source.t()) :: boolean()
  def importable?(%Source{} = source) do
    SourceMode.aggregate?(source.source_mode) and source.permitted_sync_interval_minutes != nil
  end

  defp ensure_aggregate_allowed(%Source{} = source) do
    if SourceMode.aggregate?(source.source_mode) do
      :ok
    else
      {:error, {:not_permitted, source.source_mode}}
    end
  end

  defp ensure_interval_elapsed(%Source{} = source, now) do
    case source.permitted_sync_interval_minutes do
      nil ->
        {:error, {:sync_interval_unknown, source.slug}}

      interval ->
        last = source.last_synced_at

        if is_nil(last) or DateTime.diff(now, last) >= interval * 60 do
          :ok
        else
          {:error, {:sync_too_soon, DateTime.diff(now, last), interval}}
        end
    end
  end

  defp fetch(source, adapter, opts, now) do
    case adapter.fetch(source, opts) do
      {:ok, listings} ->
        {:ok, listings}

      {:error, reason} ->
        record_health(source, now, :degraded, "Synchronization failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp store(source, listings, now) do
    Enum.reduce(listings, {0, 0, 0, 0}, fn listing, counts ->
      case Entry.prepare(source, listing) do
        {:ok, prepared} -> upsert(source, prepared, now, counts)
        {:error, _reason} -> add_skipped(counts)
      end
    end)
  end

  defp add_skipped({inserted, updated, duplicates, skipped}) do
    {inserted, updated, duplicates, skipped + 1}
  end

  defp upsert(source, prepared, now, {inserted, updated, duplicates, skipped}) do
    existing =
      Repo.one(
        from(listing in Listing,
          where: listing.source_id == ^source.id and listing.external_id == ^prepared.external_id
        )
      ) ||
        Repo.one(
          from(listing in Listing, where: listing.canonical_url == ^prepared.canonical_url)
        )

    case existing do
      nil ->
        case insert(source, prepared, now) do
          {:ok, _listing} -> {inserted + 1, updated, duplicates, skipped}
          {:error, :duplicate} -> {inserted, updated, duplicates + 1, skipped}
          {:error, :invalid} -> {inserted, updated, duplicates, skipped + 1}
        end

      %Listing{source_id: source_id} = listing ->
        if source_id == source.id do
          refresh(listing, prepared, now)
          {inserted, updated + 1, duplicates, skipped}
        else
          {inserted, updated, duplicates + 1, skipped}
        end
    end
  end

  defp insert(source, prepared, now) do
    %Listing{}
    |> Listing.changeset(
      Map.merge(prepared, %{
        source_id: source.id,
        status: :active,
        first_seen_at: now,
        last_seen_at: now
      })
    )
    |> Repo.insert()
    |> case do
      {:ok, listing} -> {:ok, listing}
      {:error, changeset} -> {:error, duplicate_error(changeset)}
    end
  end

  defp duplicate_error(changeset) do
    if Enum.any?(changeset.errors, fn {field, _errors} -> field == :canonical_url end) do
      :duplicate
    else
      :invalid
    end
  end

  defp refresh(listing, prepared, now) do
    listing
    |> Listing.changeset(
      Map.merge(prepared, %{
        status: :active,
        last_seen_at: now,
        expired_at: nil
      })
    )
    |> Repo.update()
  end

  defp expire(source, listings, now) do
    seen = listings |> Enum.map(&to_string(&1.external_id)) |> Enum.uniq()

    {expired, _result} =
      Repo.update_all(
        from(listing in Listing,
          where:
            listing.source_id == ^source.id and listing.status == :active and
              (listing.external_id not in ^seen or
                 (not is_nil(listing.expires_at) and listing.expires_at < ^now))
        ),
        set: [status: :expired, expired_at: now, updated_at: now]
      )

    expired
  end

  defp record_health(source, now, status, error) do
    source
    |> Source.changeset(%{health_status: status, last_synced_at: now, last_error: error})
    |> Repo.update()
  end
end
