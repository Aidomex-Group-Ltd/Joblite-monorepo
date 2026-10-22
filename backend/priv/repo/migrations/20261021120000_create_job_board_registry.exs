defmodule Joblite.Repo.Migrations.CreateJobBoardRegistry do
  use Ecto.Migration

  def change do
    create table(:job_board_sources) do
      add :slug, :string, null: false
      add :name, :string, null: false
      add :official_url, :string, null: false
      add :regions, {:array, :string}, null: false, default: []
      add :countries, {:array, :string}, null: false, default: []
      add :coverage_status, :string, null: false, default: "unknown"
      add :remote_eligibility, :string, null: false, default: "unknown"
      add :categories, {:array, :string}, null: false, default: []
      add :source_mode, :string, null: false
      add :access_method, :string, null: false
      add :attribution_required, :boolean, null: false, default: false
      add :attribution_text, :string
      add :canonical_link_required, :boolean, null: false, default: false
      add :permitted_sync_interval_minutes, :integer
      add :sync_interval_note, :string
      add :feed_freshness, :string, null: false, default: "unknown"
      add :last_verified_at, :utc_datetime
      add :health_status, :string, null: false, default: "unverified"
      add :status_note, :text
      add :last_synced_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:job_board_sources, [:slug])
    create index(:job_board_sources, [:source_mode])

    create table(:job_board_listings) do
      add :source_id, references(:job_board_sources, type: :binary_id, on_delete: :delete_all),
        null: false

      add :external_id, :string, null: false
      add :canonical_url, :string, null: false
      add :attribution, :string
      add :title, :string, null: false
      add :company, :string
      add :location, :string
      add :category, :string
      add :remote_eligibility, :string, null: false, default: "unknown"
      add :status, :string, null: false, default: "active"
      add :published_at, :utc_datetime
      add :expires_at, :utc_datetime
      add :first_seen_at, :utc_datetime, null: false
      add :last_seen_at, :utc_datetime, null: false
      add :expired_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:job_board_listings, [:source_id, :external_id])
    create unique_index(:job_board_listings, [:canonical_url])
    create index(:job_board_listings, [:source_id, :status])

    create table(:job_board_saved_boards) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :source_id, references(:job_board_sources, type: :binary_id, on_delete: :delete_all),
        null: false

      add :saved_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:job_board_saved_boards, [:user_id, :source_id])
    create index(:job_board_saved_boards, [:source_id])

    create table(:job_board_dismissals) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :source_id, references(:job_board_sources, type: :binary_id, on_delete: :delete_all),
        null: false

      add :dismissed_at, :utc_datetime, null: false
      add :expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:job_board_dismissals, [:user_id, :source_id])

    create table(:job_board_preferences) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :region, :string
      add :categories, {:array, :string}, null: false, default: []
      add :worldwide_only, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:job_board_preferences, [:user_id])
  end
end
