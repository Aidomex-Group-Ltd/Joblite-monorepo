defmodule JobliteWeb.Application do
  @moduledoc "Starts the single HTTP endpoint; core starts as an OTP dependency."
  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([JobliteWeb.Endpoint],
      strategy: :one_for_one,
      name: JobliteWeb.Supervisor
    )
  end

  @impl true
  def config_change(changed, _new, removed) do
    JobliteWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
