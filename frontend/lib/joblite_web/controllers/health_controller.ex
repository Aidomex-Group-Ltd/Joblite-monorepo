defmodule JobliteWeb.HealthController do
  use Phoenix.Controller, formats: [:json]

  def live(conn, _params), do: json(conn, %{status: "up"})

  def ready(conn, _params) do
    case Joblite.Health.readiness() do
      :ok ->
        json(conn, %{status: "ready"})

      {:error, :database_unavailable} ->
        conn |> put_status(:service_unavailable) |> json(%{status: "not_ready"})
    end
  end
end
