defmodule Joblite.Release do
  @moduledoc """
  Migration commands for the standalone core release.

  The core owns the schema and the migration ledger. The browser-facing
  release calls the same operation from its own product entry point; this
  module is the entry point used by the core image built from this
  repository.
  """

  @app :joblite_core

  @doc "Applies every pending migration."
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  @doc "Rolls `repo` back to `version`."
  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos, do: Application.fetch_env!(@app, :ecto_repos)
  defp load_app, do: Application.load(@app)
end
