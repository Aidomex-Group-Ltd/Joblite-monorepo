defmodule Joblite.Application do
  @moduledoc "Starts infrastructure owned by the business application."
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [{Phoenix.PubSub, name: Joblite.PubSub}] ++ repo_children()

    Supervisor.start_link(children, strategy: :one_for_one, name: Joblite.Supervisor)
  end

  defp repo_children do
    if Application.fetch_env!(:joblite_core, :start_repo), do: [Joblite.Repo], else: []
  end
end
