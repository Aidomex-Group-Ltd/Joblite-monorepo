defmodule Joblite.JobBoards.DiscoveryCycle do
  @moduledoc """
  The server-side clock of the feed discovery card.

  One singleton row records the current 30-minute slot. Every request locks the
  row, advances the slot by the number of whole cycles elapsed and returns the
  slot plus the start of the next cycle. The row survives restarts and is shared
  by every instance, so the rotation does not depend on a browser session.
  """

  use Ecto.Schema
  import Ecto.Query, warn: false

  alias Joblite.Repo

  @primary_key {:id, :integer, autogenerate: false}
  @type t :: %__MODULE__{}

  @singleton_id 1
  @cycle_seconds 30 * 60

  schema "job_board_discovery_cycles" do
    field(:slot, :integer, default: 0)
    field(:started_at, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns the current rotation offset and the instant the next cycle begins.
  `now` is injectable for deterministic tests.
  """
  @spec current(DateTime.t()) :: %{offset: non_neg_integer(), next_at: DateTime.t()}
  def current(now \\ DateTime.utc_now()) do
    now = DateTime.truncate(now, :second)

    {:ok, cycle} =
      Repo.transaction(fn ->
        cycle = lock_cycle(now)
        advance(cycle, now)
      end)

    %{offset: cycle.slot, next_at: DateTime.add(cycle.started_at, @cycle_seconds, :second)}
  end

  @doc "The length of one rotation cycle in seconds."
  @spec cycle_seconds() :: pos_integer()
  def cycle_seconds, do: @cycle_seconds

  defp lock_cycle(now) do
    case Repo.one(
           from(cycle in __MODULE__, where: cycle.id == ^@singleton_id, lock: "FOR UPDATE")
         ) do
      nil ->
        %__MODULE__{id: @singleton_id, slot: 0, started_at: now}
        |> Repo.insert!(on_conflict: :nothing, conflict_target: :id)

        Repo.one!(
          from(cycle in __MODULE__, where: cycle.id == ^@singleton_id, lock: "FOR UPDATE")
        )

      cycle ->
        cycle
    end
  end

  defp advance(cycle, now) do
    started_at = DateTime.truncate(cycle.started_at, :second)
    elapsed = DateTime.diff(now, started_at, :second)
    steps = if elapsed >= @cycle_seconds, do: div(elapsed, @cycle_seconds), else: 0

    if steps > 0 do
      started_at = DateTime.add(started_at, steps * @cycle_seconds, :second)

      cycle
      |> Ecto.Changeset.change(slot: cycle.slot + steps, started_at: started_at)
      |> Ecto.Changeset.force_change(:started_at, started_at)
      |> Repo.update!()
    else
      cycle
    end
  end
end
