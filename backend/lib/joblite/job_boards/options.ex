defmodule Joblite.JobBoards.Options do
  @moduledoc """
  The vocabulary and notice text the directory screen renders.

  The options are derived from the vocabularies of the core: the regions, the
  categories, the permission modes and the labels of the card presenter. A
  value that the core does not know is never offered here.
  """
  alias Joblite.JobBoards.{Card, Category, Region, SourceMode}

  @doc "The vocabulary the directory screen needs to render its filters."
  @spec directory() :: map()
  def directory do
    %{
      regions: Enum.map(Region.regions(), &%{value: Atom.to_string(&1), label: Region.label(&1)}),
      categories:
        Enum.map(Category.categories(), &%{value: Atom.to_string(&1), label: Category.label(&1)}),
      modes:
        Map.new(SourceMode.modes(), fn mode -> {Atom.to_string(mode), SourceMode.label(mode)} end),
      remote_eligibilities: Card.remote_labels(),
      access_methods: Card.access_labels(),
      health_statuses: Card.health_labels(),
      freshness: Card.freshness_labels(),
      remote_notice:
        "A board marked as worldwide remote may still publish roles that are limited to " <>
          "particular countries. Check eligibility on the original listing before you apply."
    }
  end
end
