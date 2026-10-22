defmodule Joblite.JobBoards.Dismissal do
  @moduledoc """
  A board a user dismissed from feed discovery. A dismissal hides the board
  from discovery rotation until it expires; revisiting the board removes the
  dismissal row.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @type t :: %__MODULE__{}

  schema "job_board_dismissals" do
    field(:user_id, :binary_id)
    field(:source_id, :binary_id)
    field(:dismissed_at, :utc_datetime)
    field(:expires_at, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(dismissal, attrs) do
    dismissal
    |> cast(attrs, [:user_id, :source_id, :dismissed_at, :expires_at])
    |> validate_required([:user_id, :source_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:source_id)
    |> unique_constraint([:user_id, :source_id])
  end
end
