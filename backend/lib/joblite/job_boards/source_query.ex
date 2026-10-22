defmodule Joblite.JobBoards.SourceQuery do
  @moduledoc """
  Query building for the job board directory.

  Search matches the board name, its official URL, the countries it covers
  and the region and category slugs it stores. Region matching treats a
  board that lists `global` as covering every region filter.
  """

  import Ecto.Query, warn: false

  alias Joblite.JobBoards.{Dismissal, Source, SourceMode}

  @doc "Builds the directory query for the given filters."
  @spec search(map()) :: Ecto.Query.t()
  def search(filters) do
    Source
    |> apply_text(filters[:text])
    |> apply_region(filters[:region])
    |> apply_worldwide(filters[:worldwide_only])
    |> order_by([source], asc: source.name)
  end

  @doc "Sources that may be promoted as a discovery card. Disabled sources are excluded."
  @spec promotable() :: Ecto.Query.t()
  def promotable do
    from(source in Source,
      where: source.source_mode in ^dumped_modes(),
      order_by: [asc: source.name]
    )
  end

  @doc "Active listings of one source, newest first."
  @spec active_listings(binary()) :: Ecto.Query.t()
  def active_listings(source_id) do
    from(listing in Joblite.JobBoards.Listing,
      where: listing.source_id == ^source_id and listing.status == :active,
      order_by: [desc: listing.published_at],
      limit: 25
    )
  end

  @doc "Sources the account dismissed and did not revisit, most recent first."
  @spec dismissed(binary()) :: Ecto.Query.t()
  def dismissed(user_id) do
    now = DateTime.utc_now()

    from(source in Source,
      join: dismissal in Dismissal,
      on: dismissal.source_id == source.id,
      where:
        dismissal.user_id == ^user_id and
          (is_nil(dismissal.expires_at) or dismissal.expires_at > ^now),
      order_by: [desc: dismissal.dismissed_at]
    )
  end

  @doc "The identifiers of the sources the account dismissed and did not revisit."
  @spec dismissed_source_ids(binary()) :: Ecto.Query.t()
  def dismissed_source_ids(user_id) do
    now = DateTime.utc_now()

    from(dismissal in Dismissal,
      where:
        dismissal.user_id == ^user_id and
          (is_nil(dismissal.expires_at) or dismissal.expires_at > ^now),
      select: dismissal.source_id
    )
  end

  defp dumped_modes do
    Enum.map(SourceMode.promotable_modes(), &Atom.to_string/1)
  end

  defp apply_text(query, nil), do: query

  defp apply_text(query, text) do
    trimmed = String.trim(text)

    if trimmed == "" do
      query
    else
      pattern = "%" <> String.downcase(trimmed) <> "%"
      slug_pattern = "%" <> slugify(trimmed) <> "%"

      from(source in query,
        where:
          ilike(source.name, ^pattern) or
            ilike(source.official_url, ^pattern) or
            fragment(
              "exists (select 1 from unnest(?) c where c ilike ?)",
              source.countries,
              ^pattern
            ) or
            fragment(
              "exists (select 1 from unnest(?) r where r ilike ?)",
              source.regions,
              ^slug_pattern
            ) or
            fragment(
              "exists (select 1 from unnest(?) k where k ilike ?)",
              source.categories,
              ^slug_pattern
            )
      )
    end
  end

  defp apply_region(query, nil), do: query

  defp apply_region(query, region) do
    slug = region_slug(region)

    from(source in query,
      where:
        fragment("? = ANY(?)", ^slug, source.regions) or
          fragment("? = ANY(?)", "global", source.regions)
    )
  end

  # The region arrives either as a slug from the interface or as an atom from
  # a stored preference. Both are compared as the slug the registry stores.
  defp region_slug(region) when is_atom(region), do: Atom.to_string(region)
  defp region_slug(region) when is_binary(region), do: region

  defp apply_worldwide(query, true) do
    from(source in query, where: source.remote_eligibility == :worldwide)
  end

  defp apply_worldwide(query, _), do: query

  defp slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[\s\-]+/, "_")
  end
end
