defmodule Joblite.JobBoards.Region do
  @moduledoc """
  The region vocabulary used by the job board directory.

  A board stores the regions it covers as slugs. A board that lists `global`
  also matches every regional filter, because global coverage includes each
  region it serves.
  """

  @regions [:global, :africa, :europe, :north_america, :latin_america, :asia_pacific_mena]

  @labels %{
    global: "Global",
    africa: "Africa",
    europe: "Europe",
    north_america: "North America",
    latin_america: "Latin America",
    asia_pacific_mena: "Asia-Pacific & MENA"
  }

  @spec regions() :: [atom()]
  def regions, do: @regions

  @doc "The label of a region given its slug or atom."
  @spec label(atom() | String.t()) :: String.t()
  def label(region) when is_atom(region), do: Map.get(@labels, region, "Unknown region")

  def label(slug) when is_binary(slug) do
    case region(slug) do
      nil -> "Unknown region"
      region -> label(region)
    end
  end

  @doc "The region for a slug, or nil when the slug is unknown."
  @spec region(String.t()) :: atom() | nil
  def region(slug) when is_binary(slug) do
    Enum.find(@regions, &(Atom.to_string(&1) == slug))
  end

  @spec valid?(term()) :: boolean()
  def valid?(region), do: region in @regions

  @spec labels() :: %{atom() => String.t()}
  def labels, do: @labels
end
