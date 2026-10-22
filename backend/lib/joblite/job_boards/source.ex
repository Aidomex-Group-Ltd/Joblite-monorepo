defmodule Joblite.JobBoards.Source do
  @moduledoc """
  A job board source in the registry.

  One row records what a board is, where it covers, how Joblite may use it and
  when that was last checked. `source_mode` is the permission switch: it alone
  decides whether listings may be imported or only linked, and it is enforced
  in `Joblite.JobBoards.SourceMode` and `Joblite.JobBoards.Sync`.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Joblite.JobBoards.{Category, Region, SourceMode}

  @primary_key {:id, :binary_id, autogenerate: true}
  @type t :: %__MODULE__{}

  @coverage_statuses [:confirmed, :unknown]
  @health_statuses [:healthy, :degraded, :unverified, :unknown]
  @freshness [:live, :hourly, :daily, :weekly, :unknown]

  schema "job_board_sources" do
    field(:slug, :string)
    field(:name, :string)
    field(:official_url, :string)
    field(:regions, {:array, :string}, default: [])
    field(:countries, {:array, :string}, default: [])
    field(:coverage_status, Ecto.Enum, values: @coverage_statuses, default: :unknown)

    field(:remote_eligibility, Ecto.Enum,
      values: SourceMode.remote_eligibilities(),
      default: :unknown
    )

    field(:categories, {:array, :string}, default: [])
    field(:source_mode, Ecto.Enum, values: SourceMode.modes())
    field(:access_method, Ecto.Enum, values: SourceMode.access_methods())
    field(:attribution_required, :boolean, default: false)
    field(:attribution_text, :string)
    field(:canonical_link_required, :boolean, default: false)
    field(:permitted_sync_interval_minutes, :integer)
    field(:sync_interval_note, :string)
    field(:feed_freshness, Ecto.Enum, values: @freshness, default: :unknown)
    field(:last_verified_at, :utc_datetime)
    field(:health_status, Ecto.Enum, values: @health_statuses, default: :unverified)
    field(:status_note, :string)
    field(:last_error, :string)
    field(:last_synced_at, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(source, attrs) do
    source
    |> cast(attrs, [
      :slug,
      :name,
      :official_url,
      :regions,
      :countries,
      :coverage_status,
      :remote_eligibility,
      :categories,
      :source_mode,
      :access_method,
      :attribution_required,
      :attribution_text,
      :canonical_link_required,
      :permitted_sync_interval_minutes,
      :sync_interval_note,
      :feed_freshness,
      :last_verified_at,
      :health_status,
      :status_note,
      :last_error,
      :last_synced_at
    ])
    |> validate_required([:slug, :name, :official_url, :source_mode, :access_method])
    |> validate_length(:name, max: 120)
    |> validate_length(:official_url, max: 500)
    |> validate_inclusion(:regions, Region.regions())
    |> validate_inclusion(:categories, Category.categories())
    |> validate_number(:permitted_sync_interval_minutes, greater_than: 0)
    |> update_change(:slug, &String.downcase/1)
    |> unique_constraint(:slug)
  end
end
