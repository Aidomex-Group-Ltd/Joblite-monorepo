defmodule JobliteWeb.AuthPagesTest do
  use JobliteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Joblite.Accounts

  setup do
    {:ok, user} =
      Accounts.register_user(%{email: "live@example.com", password: "secret-pass-1"})

    %{user: user}
  end

  describe "login page" do
    test "renders the login form for anonymous visitors", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/users/log-in")
      assert html =~ "Log in"
      assert html =~ ~s(id="user_email")
      assert html =~ ~s(id="user_password")
    end

    test "an authenticated visitor is redirected home on the disconnected mount", %{
      conn: conn,
      user: user
    } do
      conn = init_test_session(conn, %{user_token: Accounts.generate_user_session_token(user)})
      conn = get(conn, "/users/log-in")
      assert redirected_to(conn) == "/"
    end
  end

  describe "protected /account" do
    test "anonymous visitors are redirected to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, "/account")
    end

    test "an authenticated session shows the server-resolved identity", %{conn: conn, user: user} do
      token = Accounts.generate_user_session_token(user)
      conn = init_test_session(conn, %{user_token: token})

      {:ok, _view, html} = live(conn, "/account")
      assert html =~ "live@example.com"
      assert html =~ "Logged in as"
    end

    test "a revoked token no longer opens the page on a fresh mount (reconnect)", %{
      conn: conn,
      user: user
    } do
      token = Accounts.generate_user_session_token(user)
      conn = init_test_session(conn, %{user_token: token})
      {:ok, _view, _html} = live(conn, "/account")

      :ok = Accounts.delete_user_session_token(token)

      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, "/account")
    end

    test "an expired token is rejected by the connected mount path", %{conn: conn, user: user} do
      token = Accounts.generate_user_session_token(user)
      conn = init_test_session(conn, %{user_token: token})
      {:ok, _view, _html} = live(conn, "/account")

      cutoff = DateTime.add(DateTime.utc_now(), -61, :day)

      Ecto.Adapters.SQL.query!(
        Joblite.Repo,
        "UPDATE users_tokens SET inserted_at = $1",
        [DateTime.to_naive(cutoff)]
      )

      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, "/account")
    end
  end

  describe "home page" do
    test "renders for anonymous visitors with a login link", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Joblite AHIS"
      assert html =~ ~s(href="/users/log-in")
    end

    test "shows the account link for an authenticated visitor", %{conn: conn, user: user} do
      conn = init_test_session(conn, %{user_token: Accounts.generate_user_session_token(user)})
      {:ok, _view, html} = live(conn, "/")
      assert html =~ ~s(href="/account")
    end
  end
end
