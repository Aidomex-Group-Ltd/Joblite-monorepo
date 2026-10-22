defmodule Joblite.Repo.Migrations.AddPasswordlessIdentity do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string
      add :role, :string, null: false, default: "candidate"
      modify :hashed_password, :string, null: true
    end

    create constraint(:users, :users_role_must_be_valid,
             check: "role in ('candidate', 'employer')"
           )

    create table(:login_codes) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :code_hash, :binary, null: false
      add :expires_at, :utc_datetime, null: false
      add :attempts, :integer, null: false, default: 0
      add :consumed_at, :utc_datetime

      timestamps(updated_at: false, type: :utc_datetime)
    end

    create index(:login_codes, [:user_id, :inserted_at])
    create index(:login_codes, [:expires_at])
  end
end
