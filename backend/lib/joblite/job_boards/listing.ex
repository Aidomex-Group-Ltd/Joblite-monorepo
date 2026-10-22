defmodule Joblite.JobBoards.Listing do
  @moduledoc """
  A listing imported from a source that is permitted to aggregate.

  The row keeps the source's own identifier, the canonical listing URL and
  the timestamps needed to expire a listing that was removed upstream. A
  listing is never shown for a source whose mode does not allow aggregation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @type t :: %__MODULE__{}

  @statuses [:active, :expired, :removed]

  schema "job_board_listings" do
    field(:source_id, :binary_id)
    field(:external_id, :string)
    field(:canonical_url, :string)
    field(:attribution, :string)
    field(:title, :string)
    field(:company, :string)
    field(:location, :string)
    field(:category, :string)
    field(:remote_eligibility, :string, default: "unknown")
    field(:status, Ecto.Enum, values: @statuses, default: :active)
    field(:published_at, :utc_datetime)
    field(:expires_at, :utc_datetime)
    field(:first_seen_at, :utc_datetime)
    field(:last_seen_at, :utc_datetime)
    field(:expired_at, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(listing, attrs) do
    listing
    |> cast(attrs, [
      :source_id,
      :external_id,
      :canonical_url,
      :attribution,
      :title,
      :company,
      :location,
      :category,
      :remote_eligibility,
      :status,
      :published_at,
      :expires_at,
      :first_seen_at,
      :last_seen_at,
      :expired_at
    ])
    |> validate_required([:source_id, :external_id, :canonical_url, :title])
    |> validate_length(:canonical_url, max: 1000)
    |> foreign_key_constraint(:source_id)
    |> unique_constraint([:source_id, :external_id])
    |> unique_constraint(:canonical_url)
  end
end
