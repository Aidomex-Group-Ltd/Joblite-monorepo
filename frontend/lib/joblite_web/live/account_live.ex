defmodule JobliteWeb.AccountLive do
  @moduledoc """
  Minimal protected page proving the authentication boundary: only a live
  session mounted through `UserAuth.on_mount(:ensure_authenticated)` reaches
  it, and the identity shown comes from the server-resolved token, never from
  client input.
  """
  use Phoenix.LiveView, layout: {JobliteWeb.Layouts, :app}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Account")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main id="main" class="container">
      <h1>Account</h1>
      <p>Logged in as <strong>{@current_user.email}</strong></p>
      <form action="/users/log-out" method="post">
        <input type="hidden" name="_method" value="delete" />
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
        <button type="submit">Log out</button>
      </form>
    </main>
    """
  end
end
