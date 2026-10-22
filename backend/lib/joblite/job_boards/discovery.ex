defmodule Joblite.JobBoards.Discovery do
  @moduledoc """
  Pure selection rules for feed discovery cards.

  Ranking prefers a board that matches the reader's region, categories and
  worldwide-remote preference, then the sources whose terms allow aggregation.
  Rotation picks from the ranked pool while skipping the boards already shown
  in the current session, so one session never repeats a board.
  """

  alias Joblite.JobBoards.SourceMode

  @mode_weights %{
    permitted_live_aggregation: 3,
    directory_only: 2,
    permission_pending: 1
  }

  @doc "Ranks sources by relevance, then by name."
  @spec rank([Joblite.JobBoards.Source.t()], Joblite.JobBoards.Preference.t() | nil) :: [
          Joblite.JobBoards.Source.t()
        ]
  def rank(sources, preferences) do
    sources
    |> Enum.map(fn source -> {source, score(source, preferences)} end)
    |> Enum.sort_by(fn {source, points} -> {-points, source.name} end)
    |> Enum.map(fn {source, _points} -> source end)
  end

  @doc """
  Picks up to `limit` boards from the ranked pool.

  `shown` holds the identifiers already shown in the current session. They are
  skipped. `offset` rotates the choice inside the remaining pool, so a session
  that opens the feed again sees another board instead of the same one.
  """
  @spec pick([Joblite.JobBoards.Source.t()], [binary()], pos_integer(), integer()) :: [
          Joblite.JobBoards.Source.t()
        ]
  def pick(pool, shown, limit, offset)
      when is_list(shown) and is_integer(limit) and limit > 0 and is_integer(offset) do
    shown_ids = MapSet.new(shown)
    remaining = Enum.reject(pool, &MapSet.member?(shown_ids, &1.id))
    rotation = rem(offset, max(length(remaining), 1))

    remaining
    |> Enum.drop(rotation)
    |> Kernel.++(Enum.take(remaining, rotation))
    |> Enum.take(limit)
  end

  def pick(_pool, _shown, _limit, _offset), do: []

  defp score(source, nil), do: Map.get(@mode_weights, source.source_mode, 0)

  defp score(source, preferences) do
    Map.get(@mode_weights, source.source_mode, 0) +
      region_points(source, preferences) +
      category_points(source, preferences) +
      worldwide_points(source, preferences)
  end

  defp region_points(_source, %{region: nil}), do: 0

  defp region_points(source, %{region: region}) do
    regions = source.regions || []

    if Atom.to_string(region) in regions or "global" in regions, do: 3, else: 0
  end

  defp category_points(_source, %{categories: categories}) when categories in [nil, []], do: 0

  defp category_points(source, %{categories: categories}) do
    source_categories = source.categories || []
    matches = Enum.count(categories, &(&1 in source_categories))
    min(matches, 2)
  end

  defp worldwide_points(_source, %{worldwide_only: false}), do: 0

  defp worldwide_points(source, %{worldwide_only: true}) do
    if source.remote_eligibility == :worldwide, do: 2, else: 0
  end

  @doc "Modes that may be promoted in the feed, exposed for callers that need the vocabulary."
  @spec promotable_modes() :: [atom()]
  def promotable_modes, do: SourceMode.promotable_modes()
end
