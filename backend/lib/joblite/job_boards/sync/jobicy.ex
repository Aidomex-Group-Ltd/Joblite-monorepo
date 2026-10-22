defmodule Joblite.JobBoards.Sync.Jobicy do
  @moduledoc """
  Adapter for the Jobicy public jobs API.

  Jobicy's own developer page, read on 2026-10-21, allows use of its listings
  inside third-party products without individual permission when Jobicy stays
  the original source, the canonical Jobicy listing URL is preserved, the
  listings are not presented as Joblite's own postings and the attribution is
  not removed. The same page states that a synchronization pass must not start
  more than once per hour, which the source registry records as its permitted
  interval.
  """

  @behaviour Joblite.JobBoards.Sync.Adapter

  alias Joblite.JobBoards.Sync.{Industry, Transport}

  @endpoint "https://jobicy.com/api/jobs?count=200"
  @attribution "Jobicy"

  @impl true
  def slug, do: "jobicy"

  @impl true
  def attribution, do: @attribution

  @impl true
  def fetch(_source, opts) do
    transport = Keyword.get(opts, :transport, &Transport.get/1)

    case transport.(@endpoint) do
      {:ok, %{"jobs" => jobs}} when is_list(jobs) ->
        {:ok, jobs |> Enum.map(&normalize/1) |> Enum.reject(&is_nil/1)}

      {:ok, _other} ->
        {:error, :unexpected_payload}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp normalize(job) when is_map(job) do
    title = job["jobTitle"]
    url = job["url"]

    if is_binary(title) and is_binary(url) do
      %{
        external_id: to_string(job["id"]),
        canonical_url: url,
        attribution: @attribution,
        title: title,
        company: job["companyName"],
        location: job["jobGeo"],
        category: category(job["jobIndustry"]),
        remote_eligibility: remote_eligibility(job["jobGeo"]),
        published_at: parse_time(job["pubDate"]),
        expires_at: nil
      }
    end
  end

  defp normalize(_job), do: nil

  defp category(labels) when is_list(labels) do
    Enum.find_value(labels, &Industry.normalize/1)
  end

  defp category(_labels), do: nil

  defp remote_eligibility(geo) when is_binary(geo) do
    if String.contains?(String.downcase(geo), "anywhere"), do: "worldwide", else: "unknown"
  end

  defp remote_eligibility(_geo), do: "unknown"

  defp parse_time(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> DateTime.truncate(datetime, :second)
      _error -> nil
    end
  end

  defp parse_time(_value), do: nil
end
