defmodule JobliteWeb.ExploreLive.DirectoryFilters do
  @moduledoc """
  The filter state of the job board directory.

  The filters arrive from the interface as plain values. They are matched
  against the vocabulary the core published, and an unknown region is dropped
  instead of being handed to the query.
  """
  alias Joblite.JobBoards.Region

  defstruct text: "", region: nil, worldwide_only: false

  @spec new() :: %__MODULE__{}
  def new, do: %__MODULE__{}

  @doc "Reads the filters of a submitted form."
  @spec apply(%__MODULE__{}, map()) :: %__MODULE__{}
  def apply(%__MODULE__{} = filters, params) do
    %{
      filters
      | text: text(params),
        region: region(params),
        worldwide_only: worldwide_only(params)
    }
  end

  @doc "The filters in the shape the directory query expects."
  @spec to_query(%__MODULE__{}) :: map()
  def to_query(%__MODULE__{text: text, region: region, worldwide_only: worldwide_only}) do
    %{text: text, region: region, worldwide_only: worldwide_only}
  end

  @doc "True when a filter narrows the directory."
  @spec active?(%__MODULE__{}) :: boolean()
  def active?(%__MODULE__{text: text, region: region, worldwide_only: worldwide_only}) do
    text != "" or not is_nil(region) or worldwide_only
  end

  defp text(params) do
    case params["text"] do
      value when is_binary(value) -> String.trim(value)
      _other -> ""
    end
  end

  defp region(params) do
    case params["region"] do
      value when is_binary(value) ->
        if Enum.any?(Region.regions(), &(Atom.to_string(&1) == value)), do: value, else: nil

      _other ->
        nil
    end
  end

  defp worldwide_only(params) do
    params["worldwide_only"] in ["true", "on", "1"]
  end
end
