defmodule JobliteWeb.PasswordlessAuthTest do
  use JobliteWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Joblite.Accounts
  alias Swoosh.Adapters.Local.Storage.Memory

  setup do
    Memory.delete_all()
    :ok
  end

  describe "signup" do
    test "renders the passwordless signup form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/users/sign-up")

      assert html =~ "Create your account"
      assert html =~ ~s(name="user[name]")
      assert html =~ ~s(name="user[email]")
      assert html =~ ~s(name="user[role]")
      refute html =~ ~s(name="user[password]")
    end

    test "creates an account, emails a code, and verifies it", %{conn: conn} do
      conn =
        post(conn, "/users/sign-up", %{
          "user" => %{
            "name" => "Sam Rivera",
            "email" => "Sam@Example.com",
            "role" => "employer"
          }
        })

      assert redirected_to(conn) == "/users/log-in/verify"

      assert %{role: "employer", name: "Sam Rivera"} =
               Accounts.get_user_by_email("sam@example.com")

      assert get_session(conn, "pending_login_user_id")
      assert get_session(conn, "pending_login_email") == "sam@example.com"

      code = latest_code("sam@example.com")
      assert code =~ ~r/^\d{6}$/

      conn = post(conn, "/users/log-in/verify", %{"code" => code})

      assert redirected_to(conn) == "/"
      token = get_session(conn, :user_token)
      assert is_binary(token)
      user = Accounts.get_user_by_session_token(token)
      assert user.email == "sam@example.com"
      assert user.confirmed_at
    end
  end

  describe "login" do
    setup do
      {:ok, user, :new} =
        Accounts.start_passwordless_signup(%{
          email: "member@example.com",
          name: "Member",
          role: "candidate"
        })

      %{user: user}
    end

    test "sends a code and logs in without a password", %{conn: conn, user: user} do
      conn = post(conn, "/users/log-in", %{"user" => %{"email" => user.email}})

      assert redirected_to(conn) == "/users/log-in/verify"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ user.email

      conn = post(conn, "/users/log-in/verify", %{"code" => latest_code(user.email)})

      assert redirected_to(conn) == "/"
      assert Accounts.get_user_by_session_token(get_session(conn, :user_token)).id == user.id
    end

    test "an unknown address gets the same redirect but cannot verify", %{conn: conn} do
      conn = post(conn, "/users/log-in", %{"user" => %{"email" => "ghost@example.com"}})

      assert redirected_to(conn) == "/users/log-in/verify"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If that address"
      refute Accounts.get_user_by_email("ghost@example.com")

      conn = post(conn, "/users/log-in/verify", %{"code" => "123456"})
      assert redirected_to(conn) == "/users/log-in/verify"
      refute get_session(conn, :user_token)
    end

    test "a code can only be used once", %{conn: conn, user: user} do
      conn = post(conn, "/users/log-in", %{"user" => %{"email" => user.email}})
      code = latest_code(user.email)

      conn = post(conn, "/users/log-in/verify", %{"code" => code})
      assert redirected_to(conn) == "/"

      conn =
        build_conn()
        |> init_test_session(%{
          "pending_login_email" => user.email,
          "pending_login_user_id" => user.id
        })
        |> post("/users/log-in/verify", %{"code" => code})

      assert redirected_to(conn) == "/users/log-in/verify"
      refute get_session(conn, :user_token)
    end

    test "recovery sends a fresh code for an existing account", %{conn: conn, user: user} do
      conn = post(conn, "/users/recover", %{"user" => %{"email" => user.email}})
      assert redirected_to(conn) == "/users/log-in/verify"

      conn = post(conn, "/users/log-in/verify", %{"code" => latest_code(user.email)})
      assert redirected_to(conn) == "/"
      assert Accounts.get_user_by_session_token(get_session(conn, :user_token)).id == user.id
    end
  end

  defp latest_code(email) do
    Memory.all()
    |> Enum.find(fn message ->
      Enum.any?(message.to, fn {_name, address} -> address == email end)
    end)
    |> Map.fetch!(:text_body)
    |> then(&Regex.run(~r/\b(\d{6})\b/, &1))
    |> List.last()
  end
end
