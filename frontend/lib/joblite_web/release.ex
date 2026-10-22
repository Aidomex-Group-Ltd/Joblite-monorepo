defmodule JobliteWeb.Release do
  @moduledoc "Runs migrations owned by core from the assembled monolith release."

  def migrate do
    Application.ensure_all_started(:ssl)
    Application.load(:joblite_core)

    for repo <- Application.fetch_env!(:joblite_core, :ecto_repos) do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end
end
