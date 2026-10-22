defmodule Joblite.DataCaseConnectionTest do
  use Joblite.DataCase, async: true

  test "sandbox connections use the isolated joblite_test database" do
    assert %{rows: [["joblite_test"]]} =
             Ecto.Adapters.SQL.query!(Repo, "select current_database()", [])
  end

  test "tests run inside the sandbox transaction and the pool is checked out to this process" do
    assert %{rows: [[true]]} = Ecto.Adapters.SQL.query!(Repo, "select true", [])

    assert {:ok, :worked} =
             Repo.transaction(fn ->
               _ = Ecto.Adapters.SQL.query!(Repo, "select 1", [])
               :worked
             end)
  end

  test "processes without ownership cannot reuse the sandbox connection" do
    # Task.async would inherit ownership through $callers; a plain spawn must not.
    parent = self()
    ref = make_ref()

    spawn(fn ->
      send(parent, {ref, Ecto.Adapters.SQL.query(Repo, "select 1", [])})
    end)

    assert_receive {^ref, {:error, %DBConnection.OwnershipError{}}}, 1_000
  end

  test "allow_runner grants an allowed child the test connection" do
    parent = self()

    child =
      spawn(fn ->
        receive do
          :go -> send(parent, {:result, Ecto.Adapters.SQL.query(Repo, "select 1", [])})
        end
      end)

    assert :ok = allow_runner(self(), child)
    send(child, :go)

    assert_receive {:result, {:ok, %Postgrex.Result{rows: [[1]]}}}, 1_000
  end
end
