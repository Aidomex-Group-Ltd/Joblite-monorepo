defmodule Joblite.JobBoards.Sync.Entry do
  @moduledoc """
  The rules that turn a fetched listing into a stored listing.

  A listing may only be stored when it carries the attribution and the
  canonical URL that the source requires. A listing that misses one of them is
  skipped instead of being stored without the link back the terms ask for.
  """
  alias Joblite.JobBoards.Source

  @doc """
  Builds the listing that may be stored for a source.

  Returns `{:ok, listing}` or the reason the listing may not be stored.
  """
  @spec prepare(Source.t(), map()) :: {:ok, map()} | {:error, term()}
  def prepare(%Source{} = source, listing) do
    with {:ok, attribution} <- attribution_for(source, listing),
         {:ok, canonical_url} <- canonical_url_for(source, listing) do
      {:ok,
       %{
         external_id: to_string(listing.external_id),
         canonical_url: canonical_url,
         attribution: attribution,
         title: listing.title,
         company: listing.company,
         location: listing.location,
         category: listing.category,
         remote_eligibility: listing.remote_eligibility || "unknown",
         published_at: listing.published_at,
         expires_at: listing.expires_at
       }}
    end
  end

  defp attribution_for(source, listing) do
    attribution = Map.get(listing, :attribution)

    cond do
      not source.attribution_required -> {:ok, attribution}
      is_binary(attribution) and attribution != "" -> {:ok, attribution}
      true -> {:error, {:missing_attribution, source.slug}}
    end
  end

  defp canonical_url_for(source, listing) do
    url = Map.get(listing, :canonical_url)

    cond do
      not source.canonical_link_required -> {:ok, url}
      is_binary(url) and url != "" -> {:ok, url}
      true -> {:error, {:missing_canonical_url, source.slug}}
    end
  end
end
