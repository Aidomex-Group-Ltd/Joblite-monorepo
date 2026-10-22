defmodule Joblite.Repo.Migrations.CreateUsersAndSessionTokens do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :token, :binary, null: false
      add :context, :string, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(updated_at: false, type: :utc_datetime)
    end

    create unique_index(:users_tokens, [:token])
    create index(:users_tokens, [:user_id])
  end
end
