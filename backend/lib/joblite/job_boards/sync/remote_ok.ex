defmodule Joblite.JobBoards.Sync.RemoteOk do
  @moduledoc """
  Adapter for the Remote OK API.

  The API payload carries its own terms, read on 2026-10-21: the API may be
  used when the consumer links back to the Remote OK listing URL and mentions
  Remote OK as the source, and the Remote OK logo may not be reused without
  written permission. The adapter therefore keeps the canonical listing URL
  and the source attribution, and the registry caps the synchronization to one
  pass per hour because the published terms state no interval.
  """

  @behaviour Joblite.JobBoards.Sync.Adapter

  alias Joblite.JobBoards.Sync.{Industry, Transport}

  @endpoint "https://remoteok.com/api"
  @attribution "Remote OK"

  @impl true
  def slug, do: "remote-ok"

  @impl true
  def attribution, do: @attribution

  @impl true
  def fetch(_source, opts) do
    transport = Keyword.get(opts, :transport, &Transport.get/1)

    case transport.(@endpoint) do
      {:ok, jobs} when is_list(jobs) ->
        {:ok, jobs |> Enum.map(&normalize/1) |> Enum.reject(&is_nil/1)}

      {:ok, _other} ->
        {:error, :unexpected_payload}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp normalize(job) when is_map(job) do
    title = job["position"]
    url = job["url"] || job["apply_url"]

    if is_binary(title) and is_binary(url) do
      %{
        external_id: external_id(job, url),
        canonical_url: url,
        attribution: @attribution,
        title: title,
        company: job["company"],
        location: job["location"],
        category: category(job["tags"]),
        remote_eligibility: remote_eligibility(job["location"]),
        published_at: parse_time(job["date"]),
        expires_at: nil
      }
    end
  end

  defp normalize(_job), do: nil

  defp external_id(job, url) do
    case job["id"] || job["slug"] do
      nil -> url
      value -> to_string(value)
    end
  end

  defp category(tags) when is_list(tags), do: Enum.find_value(tags, &Industry.normalize/1)
  defp category(_tags), do: nil

  defp remote_eligibility(location) when is_binary(location) do
    if String.contains?(String.downcase(location), "worldwide"), do: "worldwide", else: "unknown"
  end

  defp remote_eligibility(_location), do: "unknown"

  defp parse_time(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> DateTime.truncate(datetime, :second)
      _error -> nil
    end
  end

  defp parse_time(_value), do: nil
end
