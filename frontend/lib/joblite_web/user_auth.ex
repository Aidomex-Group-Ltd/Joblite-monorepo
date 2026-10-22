defmodule JobliteWeb.UserAuth do
  @moduledoc """
  Session plug and LiveView `on_mount` hooks for the single session token
  issued by `Joblite.Accounts`. The raw token lives in the Phoenix session
  exactly once; every request and every LiveView mount (disconnected and
  connected) re-resolves it against the Accounts context, so revocation and
  expiry are enforced server-side even for already-mounted pages.

  A LiveView that acts on the account of the visitor resolves the identity
  again through `current_user/1`. The raw token is kept in the private part of
  the socket and is never assigned, so it never reaches the client.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias Joblite.Accounts
  alias Joblite.Accounts.User
  alias Phoenix.Component
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  @session_key :user_token
  @socket_token_key :joblite_session_token
  @pending_user_key "pending_login_user_id"
  @pending_email_key "pending_login_email"

  @doc "Plug callback; the action atom is passed through unchanged."
  def init(action), do: action

  @doc """
  Plug entry points:

    * `plug JobliteWeb.UserAuth, :fetch_current_user`
    * `plug JobliteWeb.UserAuth, :redirect_if_user_is_authenticated`
  """
  def call(conn, :fetch_current_user), do: fetch_current_user(conn, [])

  def call(conn, :redirect_if_user_is_authenticated) do
    redirect_if_user_is_authenticated(conn, [])
  end

  @doc "Assigns `:current_user` from the session token, or nil when absent/invalid."
  @spec fetch_current_user(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def fetch_current_user(conn, _opts) do
    user =
      case get_session(conn, @session_key) do
        nil -> nil
        token -> Accounts.get_user_by_session_token(token)
      end

    assign(conn, :current_user, user)
  end

  @doc "Issues a fresh session token, renews and clears the session to defeat fixation, and redirects."
  @spec log_in_user(Plug.Conn.t(), term()) :: Plug.Conn.t()
  def log_in_user(conn, user) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> renew_session()
    |> put_session(@session_key, token)
    |> redirect(to: "/")
  end

  @doc "Revokes the session token (if any), renews and clears the session, and redirects."
  @spec log_out_user(Plug.Conn.t()) :: Plug.Conn.t()
  def log_out_user(conn) do
    if token = get_session(conn, @session_key) do
      Accounts.delete_user_session_token(token)
    end

    conn
    |> renew_session()
    |> redirect(to: "/")
  end

  @doc """
  Remembers which address is waiting for a sign-in code. The id is nil for an
  unknown address; keeping the email lets the verification page respond the
  same way without confirming whether an account exists.
  """
  @spec put_pending_login(Plug.Conn.t(), String.t(), User.t() | nil) :: Plug.Conn.t()
  def put_pending_login(conn, email, user) when is_binary(email) do
    conn
    |> put_session(@pending_email_key, email)
    |> put_session(@pending_user_key, user && user.id)
  end

  @doc "The pending sign-in identity from a session map."
  @spec pending_login(map()) :: %{email: String.t() | nil, user_id: String.t() | nil}
  def pending_login(session) when is_map(session) do
    %{email: session[@pending_email_key], user_id: session[@pending_user_key]}
  end

  @doc "Forgets the pending sign-in identity."
  @spec clear_pending_login(Plug.Conn.t()) :: Plug.Conn.t()
  def clear_pending_login(conn) do
    conn
    |> delete_session(@pending_email_key)
    |> delete_session(@pending_user_key)
  end

  @doc """
  The account that owns the current session, resolved again now.

  The session token is taken from the private part of the socket and resolved
  through `Joblite.Accounts`, so a revoked or expired session cannot act on
  the account it used to own.
  """
  @spec current_user(Socket.t()) :: User.t() | nil
  def current_user(%Socket{} = socket), do: resolve(token(socket))

  @doc """
  LiveView `on_mount` hooks:

    * `:mount_current_user` — assigns `:current_user` without enforcing presence
    * `:ensure_authenticated` — assigns and halts anonymous mounts toward login
    * `:redirect_if_user_is_authenticated` — halts authenticated mounts away from login
  """
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> LiveView.put_flash(:error, "You must log in to access this page.")
        |> LiveView.redirect(to: "/users/log-in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, LiveView.redirect(socket, to: "/")}
    else
      {:cont, socket}
    end
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: "/")
      |> halt()
    else
      conn
    end
  end

  defp mount_current_user(socket, session) do
    token = session["user_token"]
    socket = put_token(socket, token)

    Component.assign_new(socket, :current_user, fn -> resolve(token) end)
  end

  defp resolve(nil), do: nil
  defp resolve(token) when is_binary(token), do: Accounts.get_user_by_session_token(token)
  defp resolve(_token), do: nil

  defp put_token(socket, token) do
    %{socket | private: Map.put(socket.private, @socket_token_key, token)}
  end

  defp token(%Socket{private: private}), do: Map.get(private, @socket_token_key)
end
