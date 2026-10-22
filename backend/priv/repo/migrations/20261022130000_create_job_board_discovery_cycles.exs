defmodule Joblite.Repo.Migrations.CreateJobBoardDiscoveryCycles do
  use Ecto.Migration

  def change do
    create table(:job_board_discovery_cycles, primary_key: false) do
      add :id, :integer, primary_key: true
      add :slot, :integer, null: false, default: 0
      add :started_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    execute(
      """
      INSERT INTO job_board_discovery_cycles (id, slot, started_at, inserted_at, updated_at)
      VALUES (1, 0, date_trunc('second', now()), date_trunc('second', now()), date_trunc('second', now()))
      ON CONFLICT (id) DO NOTHING
      """,
      "DELETE FROM job_board_discovery_cycles WHERE id = 1"
    )
  end
end
