defmodule Joblite.HealthTest do
  use Joblite.DataCase, async: true

  test "readiness answers :ok when the test database responds" do
    assert :ok = Joblite.Health.readiness()
  end

  test "readiness maps a missing repository process to :database_unavailable" do
    defmodule NeverStartedRepo do
    end

    assert {:error, :database_unavailable} = Joblite.Health.readiness(NeverStartedRepo)
  end
end
