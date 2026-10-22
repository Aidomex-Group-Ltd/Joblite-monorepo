import Config

config :joblite_core,
  ecto_repos: [Joblite.Repo],
  # The Repo starts in every environment, including :test, where the SQL
  # Sandbox pool in test/ is used against the isolated joblite_test database.
  start_repo: true

config :joblite_core, Joblite.Repo,
  migration_primary_key: [name: :id, type: :binary_id],
  migration_foreign_key: [type: :binary_id],
  pool_size: 5

if config_env() != :prod do
  database = if config_env() == :test, do: "joblite_test", else: "joblite_dev_db"

  config :joblite_core, Joblite.Repo,
    # Port 5543 matches compose.yaml: the development host already runs another
    # PostgreSQL on 5432. Set DATABASE_URL to override on any other host.
    url:
      System.get_env("DATABASE_URL") ||
        "ecto://joblite:joblite_local_only@localhost:5543/#{database}"
end

if config_env() == :test do
  config :joblite_core, Joblite.Repo, pool: Ecto.Adapters.SQL.Sandbox
end
