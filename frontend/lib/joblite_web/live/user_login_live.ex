defmodule JobliteWeb.UserLoginLive do
  @moduledoc """
  Passwordless email entry for login and account recovery. Both forms request a
  one-time code; a password form remains for accounts created before
  passwordless sign-in existed.
  """
  use Phoenix.LiveView, layout: {JobliteWeb.Layouts, :app}

  @impl true
  def mount(_params, _session, socket) do
    title = if socket.assigns.live_action == :recover, do: "Recover account", else: "Log in"
    {:ok, assign(socket, page_title: title)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main id="main" class="container">
      <h1>{@page_title}</h1>
      <p>
        {if @live_action == :recover,
          do: "Enter your email and we will send a single-use code that gets you back in.",
          else: "No password needed. We will email you a six-digit sign-in code."}
      </p>

      <form
        action={if @live_action == :recover, do: "/users/recover", else: "/users/log-in"}
        method="post"
      >
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
        <p>
          <label for="user_email">Email</label>
          <input id="user_email" name="user[email]" type="email" autocomplete="email" required />
        </p>
        <p><button type="submit">Email me a code</button></p>
      </form>

      <p>
        New to Joblite? <a href="/users/sign-up">Create an account</a>. <a href="/users/recover">Recover an account</a>.
      </p>

      <details>
        <summary>Use a password instead</summary>
        <form action="/users/log-in" method="post">
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
          <p>
            <label for="password_email">Email</label>
            <input id="password_email" name="user[email]" type="email" autocomplete="email" required />
          </p>
          <p>
            <label for="user_password">Password</label>
            <input
              id="user_password"
              name="user[password]"
              type="password"
              autocomplete="current-password"
              required
            />
          </p>
          <p><button type="submit">Log in with password</button></p>
        </form>
      </details>
    </main>
    """
  end
end
