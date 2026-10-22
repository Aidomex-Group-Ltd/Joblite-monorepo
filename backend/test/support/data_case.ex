defmodule Joblite.DataCase do
  @moduledoc """
  Async-capable test case for core code that touches the database.

  Every test runs inside an Ecto SQL Sandbox transaction against the isolated
  `joblite_test` database; the transaction rolls back on exit. `start_owner!/2`
  gives the test process (and, in shared mode, its allowed children) ownership
  of one pooled connection, which is also the lifecycle the future LiveView and
  worker tests must integrate with.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Joblite.Repo
      import Ecto.Query
      import Joblite.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Joblite.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    {:ok, sandbox_pid: pid}
  end

  @doc "Allows a spawned process (LiveView, worker, Task) to reuse this test's connection."
  @spec allow_runner(pid(), pid()) :: :ok
  def allow_runner(owner, child)
      when is_pid(owner) and is_pid(child) do
    Ecto.Adapters.SQL.Sandbox.allow(Joblite.Repo, owner, child)
  end

  @doc "Extracts `{field => [message]}` maps from a changeset for assertions."
  @spec errors_on(Ecto.Changeset.t()) :: %{optional(atom()) => [String.t()]}
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
