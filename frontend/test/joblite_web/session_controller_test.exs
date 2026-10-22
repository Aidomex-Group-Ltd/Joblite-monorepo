defmodule JobliteWeb.SessionControllerTest do
  use JobliteWeb.ConnCase, async: true

  alias Joblite.Accounts

  setup do
    {:ok, user} =
      Accounts.register_user(%{email: "login@example.com", password: "secret-pass-1"})

    %{user: user}
  end

  describe "POST /users/log-in" do
    test "valid credentials renew the session with a fresh token and redirect home", %{
      conn: conn,
      user: user
    } do
      conn = post(conn, "/users/log-in", user: %{email: user.email, password: "secret-pass-1"})

      assert redirected_to(conn) == "/"
      token = get_session(conn, :user_token)
      assert is_binary(token)
      assert Accounts.get_user_by_session_token(token).id == user.id
    end

    test "wrong password flashes an error and issues no session token", %{conn: conn} do
      conn =
        post(conn, "/users/log-in",
          user: %{
            email: "login@example.com",
            password: "not-the-password"
          }
        )

      assert redirected_to(conn) == "/users/log-in"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password."
    end

    test "unknown email follows the same failure path", %{conn: conn} do
      conn =
        post(conn, "/users/log-in", user: %{email: "ghost@example.com", password: "whatever-pw"})

      assert redirected_to(conn) == "/users/log-in"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password."
    end
  end

  describe "DELETE /users/log-out" do
    test "revokes the stored token and does not return it in the renewed session", %{
      conn: conn,
      user: user
    } do
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> init_test_session(%{user_token: token})
        |> delete("/users/log-out")

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Logged out successfully."
      refute Accounts.get_user_by_session_token(token)
      refute get_session(conn, :user_token) == token
    end

    test "logout without a session token is still a clean redirect", %{conn: conn} do
      conn = delete(conn, "/users/log-out")
      assert redirected_to(conn) == "/"
    end
  end
end
