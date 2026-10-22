defmodule Joblite.Health do
  @moduledoc "Small public boundary for runtime metadata and database readiness."

  @spec architecture() :: map()
  def architecture do
    %{ui: "Phoenix LiveView", database: "PostgreSQL", runtime: "one release"}
  end

  @doc """
  Bounded readiness probe. The default repository is the monolith's one Repo;
  the argument exists so failure mapping can be tested without stopping it.
  """
  @spec readiness(module()) :: :ok | {:error, :database_unavailable}
  def readiness(repo \\ Joblite.Repo) do
    if Process.whereis(repo), do: check_database(repo), else: unavailable()
  end

  defp check_database(repo) do
    case Ecto.Adapters.SQL.query(repo, "SELECT 1", [], timeout: 2_000) do
      {:ok, _result} -> :ok
      {:error, _reason} -> unavailable()
    end
  rescue
    DBConnection.ConnectionError -> unavailable()
  catch
    :exit, _reason -> unavailable()
  end

  defp unavailable, do: {:error, :database_unavailable}
end
