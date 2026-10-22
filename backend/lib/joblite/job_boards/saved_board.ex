defmodule Joblite.JobBoards.SavedBoard do
  @moduledoc """
  A board a user saved for later. The row is user owned: only the owning user
  may read or delete it, and the unique index keeps one row per pair.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @type t :: %__MODULE__{}

  schema "job_board_saved_boards" do
    field(:user_id, :binary_id)
    field(:source_id, :binary_id)
    field(:saved_at, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(saved_board, attrs) do
    saved_board
    |> cast(attrs, [:user_id, :source_id, :saved_at])
    |> validate_required([:user_id, :source_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:source_id)
    |> unique_constraint([:user_id, :source_id])
  end
end
