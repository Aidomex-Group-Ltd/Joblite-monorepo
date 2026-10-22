defmodule JobliteWeb.UserVerifyLive do
  @moduledoc "Six-digit code entry for passwordless login, signup and recovery."
  use Phoenix.LiveView, layout: {JobliteWeb.Layouts, :app}

  alias JobliteWeb.UserAuth

  @impl true
  def mount(_params, session, socket) do
    case UserAuth.pending_login(session) do
      %{email: email} when is_binary(email) ->
        {:ok, assign(socket, page_title: "Check your email", email: email)}

      _ ->
        {:ok, redirect(socket, to: "/users/log-in")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main id="main" class="container">
      <h1>Check your email</h1>
      <p>We sent a six-digit code to <strong>{@email}</strong>. It expires in 15 minutes.</p>

      <form action="/users/log-in/verify" method="post">
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
        <p>
          <label for="code">Sign-in code</label>
          <input
            id="code"
            name="code"
            type="text"
            inputmode="numeric"
            pattern="[0-9]{6}"
            maxlength="6"
            autocomplete="one-time-code"
            required
          />
        </p>
        <p><button type="submit">Verify and log in</button></p>
      </form>

      <form action="/users/log-in/resend" method="post">
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
        <p><button type="submit">Send another code</button></p>
      </form>

      <p><a href="/users/log-in">Use a different email</a></p>
    </main>
    """
  end
end
