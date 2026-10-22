defmodule Joblite.JobBoards.Preference do
  @moduledoc """
  The job discovery preferences of one account.

  Preferences are optional. An account without them still receives discovery
  cards, ranked with the neutral ordering for feed candidates.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Joblite.JobBoards.Category
  alias Joblite.JobBoards.Region

  @primary_key {:id, :binary_id, autogenerate: true}
  @type t :: %__MODULE__{}

  schema "job_board_preferences" do
    field(:user_id, :binary_id)
    field(:region, Ecto.Enum, values: Region.regions())
    field(:categories, {:array, :string}, default: [])
    field(:worldwide_only, :boolean, default: false)

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(preference, attrs) do
    preference
    |> cast(attrs, [:user_id, :region, :categories, :worldwide_only])
    |> validate_required([:user_id])
    |> validate_categories()
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id)
  end

  @doc """
  Normalizes the preferences that arrive from the interface.

  A region arrives as a slug and is matched against the known vocabulary. An
  unknown slug is handed on unchanged, so the changeset refuses it instead of
  storing a guess. The categories keep their slugs and the flag is always
  written, so clearing the preferences really clears them.
  """
  @spec normalize(map()) :: map()
  def normalize(attrs) do
    attrs
    |> Map.put(:region, normalize_region(Map.get(attrs, :region)))
    |> Map.put(:categories, normalize_categories(Map.get(attrs, :categories) || []))
    |> Map.put(:worldwide_only, Map.get(attrs, :worldwide_only) == true)
  end

  defp normalize_region(nil), do: nil
  defp normalize_region(region) when is_atom(region), do: region

  defp normalize_region(slug) when is_binary(slug) do
    case Region.region(slug) do
      nil -> slug
      region -> region
    end
  end

  defp normalize_categories(categories) when is_list(categories) do
    Enum.map(categories, fn
      category when is_atom(category) -> Atom.to_string(category)
      category when is_binary(category) -> category
    end)
  end

  defp validate_categories(changeset) do
    validate_change(changeset, :categories, fn :categories, categories ->
      case Enum.reject(categories, &Category.valid_slug?/1) do
        [] ->
          []

        unknown ->
          [{:categories, {"has unknown categories: #{Enum.join(unknown, ", ")}", []}}]
      end
    end)
  end
end
