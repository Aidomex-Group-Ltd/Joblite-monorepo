defmodule JobliteWeb.SessionController do
  @moduledoc "HTTP login/logout actions; domain verification stays in `Joblite.Accounts`."
  use Phoenix.Controller, formats: [:html]

  alias Joblite.Accounts
  alias JobliteWeb.UserAuth

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_by_email_password(email, password) do
      {:ok, user} ->
        UserAuth.log_in_user(conn, user)

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid email or password.")
        |> redirect(to: "/users/log-in")
    end
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
    |> put_flash(:info, "Logged out successfully.")
  end
end
