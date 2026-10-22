defmodule JobliteWeb.ConnCase do
  @moduledoc """
  Test case template for HTTP and connected LiveView tests.

  Test support (not UI code) manages Ecto SQL Sandbox ownership of the core
  Repo so connected LiveView processes can participate in the test
  transaction through `$callers` inheritance. UI modules themselves never
  reference the Repo.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest

      @endpoint JobliteWeb.Endpoint
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Joblite.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
