defmodule Joblite.JobBoards.Card do
  @moduledoc """
  Display-ready descriptions of a board.

  The directory and the feed cards share this presenter so both show the same
  integration status, coverage and eligibility context. Unknown information is
  rendered as unknown instead of being filled in.
  """

  alias Joblite.JobBoards.{Category, Listing, Region, Source, SourceMode}

  @remote_labels %{
    worldwide: "Worldwide remote",
    regional: "Regional remote",
    country_restricted: "Country restricted",
    unknown: "Remote eligibility unknown"
  }

  @access_labels %{
    api: "Public API",
    rss: "RSS feed",
    partner_agreement: "Partner agreement",
    official_link: "Official link only"
  }

  @freshness_labels %{
    live: "Live feed",
    hourly: "Updated hourly",
    daily: "Updated daily",
    weekly: "Updated weekly",
    unknown: "Freshness unknown"
  }

  @health_labels %{
    healthy: "Feed healthy",
    degraded: "Feed degraded",
    unverified: "Not monitored yet",
    unknown: "Health unknown"
  }

  @status_tones %{
    permitted_live_aggregation: "candidate",
    directory_only: "directory",
    permission_pending: "pending",
    temporarily_disabled: "disabled"
  }

  @remote_description "Find remote job listings across a range of roles and industries."
  @general_description "Explore job listings and discover your next opportunity."
  @external_description "Explore job listings on this job board."

  @mode_notes %{
    permitted_live_aggregation:
      "Its published terms allow Joblite to import the listings with attribution and a link back.",
    directory_only:
      "Its published terms do not allow republication, so the board stays an outbound link.",
    permission_pending:
      "Written permission is requested and not recorded yet, so the board stays an outbound link.",
    temporarily_disabled: "The board is switched off for now."
  }

  @doc "Builds the display data for one board."
  @spec present(Source.t(), Listing.t() | nil) :: map()
  def present(%Source{} = source, _listing \\ nil) do
    regions = source.regions || []
    categories = source.categories || []

    %{
      id: source.id,
      slug: source.slug,
      name: source.name,
      url: source.official_url,
      region_labels: Enum.map(regions, &Region.label/1),
      regions: regions,
      mode: source.source_mode,
      source_mode: source.source_mode,
      mode_label: SourceMode.label(source.source_mode),
      description: description(source),
      remote_summary: remote_summary(source),
      listing: nil,
      categories: categories
    }
  end

  defdelegate for_source(source, listing \\ nil), to: __MODULE__, as: :present

  def full(%Source{} = source, listing \\ nil) do
    regions = source.regions || []
    categories = source.categories || []

    %{
      id: source.id,
      slug: source.slug,
      name: source.name,
      url: source.official_url,
      mode: source.source_mode,
      mode_label: SourceMode.label(source.source_mode),
      mode_note:
        Map.get(
          @mode_notes,
          source.source_mode,
          "The integration status of this board is unknown."
        ),
      status_tone: Map.get(@status_tones, source.source_mode, "directory"),
      description: description(source),
      remote_summary: remote_summary(source),
      regions: regions,
      region_labels: Enum.map(regions, &Region.label/1),
      regions_summary: regions_summary(regions),
      coverage_status: source.coverage_status,
      coverage_label: coverage_label(source),
      countries: source.countries || [],
      countries_summary: countries_summary(source.countries || [], source),
      remote_eligibility: source.remote_eligibility,
      remote_label:
        Map.get(@remote_labels, source.remote_eligibility, "Remote eligibility unknown"),
      categories: categories,
      category_labels: Enum.map(categories, &Category.label/1),
      categories_summary: categories_summary(categories),
      access_method: source.access_method,
      access_label: Map.get(@access_labels, source.access_method, "Access unknown"),
      attribution_required: source.attribution_required,
      attribution_text: source.attribution_text,
      canonical_link_required: source.canonical_link_required,
      sync_label: sync_label(source),
      freshness_label: Map.get(@freshness_labels, source.feed_freshness, "Freshness unknown"),
      last_verified_label: verified_label(source),
      health_status: source.health_status,
      health_label: Map.get(@health_labels, source.health_status, "Health unknown"),
      status_note: source.status_note,
      last_error: source.last_error,
      listing: listing_data(listing)
    }
  end

  defp listing_data(nil), do: nil

  defp listing_data(%Listing{} = listing) do
    %{
      title: listing.title,
      canonical_url: listing.canonical_url,
      attribution: listing.attribution,
      company: listing.company,
      location: listing.location,
      published_label: published_label(listing)
    }
  end

  defp published_label(%Listing{published_at: nil}), do: nil

  defp published_label(%Listing{published_at: published_at}) do
    Date.to_iso8601(DateTime.to_date(published_at))
  end

  @doc "Labels for the remote eligibility of a board."
  @spec remote_labels() :: %{atom() => String.t()}
  def remote_labels, do: @remote_labels

  @doc "Labels for the access method of a board."
  @spec access_labels() :: %{atom() => String.t()}
  def access_labels, do: @access_labels

  @doc "Labels for the freshness of a board feed."
  @spec freshness_labels() :: %{atom() => String.t()}
  def freshness_labels, do: @freshness_labels

  @doc "Labels for the health of a board feed."
  @spec health_labels() :: %{atom() => String.t()}
  def health_labels, do: @health_labels

  defp description(%Source{} = source) do
    cond do
      not SourceMode.aggregate?(source.source_mode) -> @external_description
      remote_focused?(source) -> @remote_description
      true -> @general_description
    end
  end

  defp remote_focused?(%Source{remote_eligibility: eligibility}),
    do: eligibility in [:worldwide, :regional]

  defp remote_summary(%Source{remote_eligibility: :worldwide} = source) do
    if worldwide_supported?(source), do: "Worldwide remote", else: "Remote opportunities"
  end

  defp remote_summary(%Source{remote_eligibility: eligibility})
       when eligibility in [:regional, :country_restricted],
       do: "Remote opportunities"

  defp remote_summary(_source), do: nil

  defp worldwide_supported?(%Source{coverage_status: :confirmed, regions: regions}) do
    is_list(regions) and "global" in regions
  end

  defp worldwide_supported?(_source), do: false

  defp coverage_label(%{coverage_status: :confirmed} = source) do
    "Coverage confirmed " <> verified_label(source)
  end

  defp coverage_label(_source), do: "Coverage pending review"

  defp regions_summary([]), do: "Regions pending review"
  defp regions_summary(regions), do: Enum.map_join(regions, ", ", &Region.label/1)

  defp categories_summary([]), do: "Categories pending review"
  defp categories_summary(categories), do: Enum.map_join(categories, ", ", &Category.label/1)

  defp countries_summary([], %{remote_eligibility: :worldwide}), do: "Every country"
  defp countries_summary([], _source), do: "Countries pending review"
  defp countries_summary(countries, _source), do: Enum.join(countries, ", ")

  defp sync_label(%{permitted_sync_interval_minutes: nil}), do: "No synchronization permitted"

  defp sync_label(%{permitted_sync_interval_minutes: minutes}) do
    "Sync at most every #{minutes} minute#{if minutes == 1, do: "", else: "s"}"
  end

  defp verified_label(%{last_verified_at: nil}), do: "on an unknown date"

  defp verified_label(%{last_verified_at: verified_at}) do
    "on " <> Date.to_iso8601(DateTime.to_date(verified_at))
  end
end
