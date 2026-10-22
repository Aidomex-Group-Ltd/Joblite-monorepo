defmodule JobliteWeb.UserSignupLive do
  @moduledoc "Passwordless signup: name, email and how the account will use Joblite."
  use Phoenix.LiveView, layout: {JobliteWeb.Layouts, :app}

  alias Joblite.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Create account", roles: User.roles())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main id="main" class="container">
      <h1>Create your account</h1>
      <p>We will email you a six-digit code. No password to remember.</p>

      <form action="/users/sign-up" method="post">
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
        <p>
          <label for="user_name">Name</label>
          <input
            id="user_name"
            name="user[name]"
            type="text"
            autocomplete="name"
            maxlength="80"
            required
          />
        </p>
        <p>
          <label for="user_email">Email</label>
          <input id="user_email" name="user[email]" type="email" autocomplete="email" required />
        </p>
        <p>
          <label for="user_role">I am here to</label>
          <select id="user_role" name="user[role]" required>
            <option value="candidate">Find work</option>
            <option value="employer">Hire people</option>
          </select>
        </p>
        <p><button type="submit">Email me a code</button></p>
      </form>

      <p>Already have an account? <a href="/users/log-in">Log in</a>.</p>
    </main>
    """
  end
end
