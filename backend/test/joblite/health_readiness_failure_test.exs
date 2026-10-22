defmodule Joblite.HealthReadinessFailureTest do
  use ExUnit.Case, async: false

  defmodule UnreachableRepo do
    use Ecto.Repo, otp_app: :joblite_core, adapter: Ecto.Adapters.Postgres
  end

  setup do
    # 127.0.0.1:5544 is a deliberately closed port on the development host
    # (verified free before P02); connections are refused immediately.
    start_supervised!(
      {UnreachableRepo, url: "ecto://nobody:secret@127.0.0.1:5544/none", pool_size: 1}
    )

    :ok
  end

  test "readiness maps an unreachable database to :database_unavailable" do
    assert {:error, :database_unavailable} = Joblite.Health.readiness(UnreachableRepo)
  end
end
