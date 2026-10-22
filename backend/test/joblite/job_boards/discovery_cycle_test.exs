defmodule Joblite.JobBoards.DiscoveryCycleTest do
  use Joblite.DataCase, async: false

  alias Joblite.JobBoards.DiscoveryCycle
  alias Joblite.Repo

  @start ~U[2026-10-22 12:00:00Z]

  setup do
    Repo.delete_all(DiscoveryCycle)
    Repo.insert!(%DiscoveryCycle{id: 1, slot: 0, started_at: @start})
    :ok
  end

  test "returns the current slot and the start of the next cycle" do
    assert %{offset: 0, next_at: ~U[2026-10-22 12:30:00Z]} =
             DiscoveryCycle.current(DateTime.add(@start, 10, :minute))
  end

  test "does not rotate before thirty minutes have passed" do
    assert %{offset: 0, next_at: ~U[2026-10-22 12:30:00Z]} =
             DiscoveryCycle.current(DateTime.add(@start, 29, :minute))
  end

  test "advances once at thirty minutes and persists the slot" do
    assert %{offset: 1, next_at: ~U[2026-10-22 13:00:00Z]} =
             DiscoveryCycle.current(DateTime.add(@start, 31, :minute))

    assert Repo.get!(DiscoveryCycle, 1).slot == 1
  end

  test "catches up by whole cycles after a quiet period" do
    assert %{offset: 3, next_at: ~U[2026-10-22 14:00:00Z]} =
             DiscoveryCycle.current(DateTime.add(@start, 91, :minute))
  end
end
