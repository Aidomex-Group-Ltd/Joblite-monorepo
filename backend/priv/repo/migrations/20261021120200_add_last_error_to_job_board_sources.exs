defmodule Joblite.Repo.Migrations.AddLastErrorToJobBoardSources do
  use Ecto.Migration

  def change do
    # The last synchronization failure is kept apart from `status_note`, which
    # holds the verified terms of the source and must not be overwritten by a
    # transient error.
    alter table(:job_board_sources) do
      add :last_error, :string
    end
  end
end
