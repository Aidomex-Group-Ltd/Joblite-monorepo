defmodule JobliteWeb.EmailAuthController do
  @moduledoc """
  Passwordless email entry points. Login and recovery only send a code when an
  account exists, but always redirect to the verification page; account
  existence is never revealed by the response. Signup creates an account with a
  name and role, then follows the same code flow.
  """

  use Phoenix.Controller, formats: [:html]

  require Logger

  alias Joblite.Accounts
  alias Joblite.Accounts.User
  alias JobliteWeb.Emails.LoginCodeEmail
  alias JobliteWeb.UserAuth

  def login(conn, %{"user" => %{"password" => password} = attrs})
      when is_binary(password) and password != "" do
    password_login(conn, attrs)
  end

  def login(conn, %{"user" => attrs}), do: request_code(conn, attrs["email"], "/users/log-in")

  def recover(conn, %{"user" => attrs}), do: request_code(conn, attrs["email"], "/users/recover")

  def signup(conn, %{"user" => attrs}) do
    case Accounts.start_passwordless_signup(attrs) do
      {:ok, user, _status} ->
        send_code(conn, user, "/users/sign-up")

      {:error, changeset} ->
        conn
        |> put_flash(:error, changeset_message(changeset))
        |> redirect(to: "/users/sign-up")
    end
  end

  def verify(conn, %{"code" => code}) do
    pending = UserAuth.pending_login(Plug.Conn.get_session(conn))

    with user_id when is_binary(user_id) <- pending.user_id,
         %User{} = user <- Accounts.get_user(user_id),
         {:ok, user} <- Accounts.verify_login_code(user, code) do
      conn
      |> UserAuth.clear_pending_login()
      |> UserAuth.log_in_user(user)
    else
      _ ->
        conn
        |> put_flash(:error, "That code is invalid or has expired.")
        |> redirect(to: "/users/log-in/verify")
    end
  end

  def resend(conn, _params) do
    pending = UserAuth.pending_login(Plug.Conn.get_session(conn))

    case pending.user_id && Accounts.get_user(pending.user_id) do
      %User{} = user ->
        send_code(conn, user, "/users/log-in/verify")

      _ ->
        conn
        |> put_flash(:error, "Start again with your email address.")
        |> redirect(to: "/users/log-in")
    end
  end

  defp request_code(conn, email, return_to) do
    if is_binary(email) and String.trim(email) != "" do
      case Accounts.issue_login_code(String.trim(email)) do
        {:ok, :ignored} ->
          conn
          |> UserAuth.put_pending_login(String.trim(email), nil)
          |> put_flash(:info, "If that address has a Joblite account, a code is on its way.")
          |> redirect(to: "/users/log-in/verify")

        {:ok, {:issued, user, code}} ->
          deliver_code(conn, user, code, return_to)

        {:error, {:rate_limited, seconds}} ->
          rate_limited(conn, return_to, seconds)
      end
    else
      conn
      |> put_flash(:error, "Enter your email address.")
      |> redirect(to: return_to)
    end
  end

  defp send_code(conn, %User{} = user, return_to) do
    case Accounts.issue_login_code(user.email) do
      {:ok, {:issued, user, code}} -> deliver_code(conn, user, code, return_to)
      {:ok, :ignored} -> deliver_code(conn, user, nil, return_to)
      {:error, {:rate_limited, seconds}} -> rate_limited(conn, return_to, seconds)
    end
  end

  defp deliver_code(conn, %User{} = user, code, return_to) do
    if is_binary(code) and LoginCodeEmail.deliver(user, code) == :ok do
      conn
      |> UserAuth.put_pending_login(user.email, user)
      |> put_flash(:info, "We sent a 6-digit code to #{user.email}.")
      |> redirect(to: "/users/log-in/verify")
    else
      Accounts.revoke_login_codes(user)
      Logger.error("sign-in code delivery failed")

      conn
      |> put_flash(:error, "We could not send the email. Please try again.")
      |> redirect(to: return_to)
    end
  end

  defp rate_limited(conn, return_to, seconds) do
    minutes = max(div(seconds + 59, 60), 1)

    conn
    |> put_flash(:error, "Too many codes requested. Try again in #{minutes} minute(s).")
    |> redirect(to: return_to)
  end

  defp password_login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_by_email_password(email, password) do
      {:ok, user} ->
        UserAuth.log_in_user(conn, user)

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid email or password.")
        |> redirect(to: "/users/log-in")
    end
  end

  defp password_login(conn, _attrs) do
    conn
    |> put_flash(:error, "Invalid email or password.")
    |> redirect(to: "/users/log-in")
  end

  defp changeset_message(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, &"#{Phoenix.Naming.humanize(field)} #{&1}")
    end)
    |> List.first()
    |> case do
      nil -> "Check the form and try again."
      message -> message <> "."
    end
  end
end
