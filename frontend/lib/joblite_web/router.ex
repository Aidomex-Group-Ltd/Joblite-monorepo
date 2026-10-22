defmodule JobliteWeb.Router do
  use Phoenix.Router
  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JobliteWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug JobliteWeb.UserAuth, :fetch_current_user
  end

  pipeline :redirect_if_user_is_authenticated do
    plug JobliteWeb.UserAuth, :redirect_if_user_is_authenticated
  end

  scope "/", JobliteWeb do
    get "/health/live", HealthController, :live
    get "/health/ready", HealthController, :ready
  end

  scope "/", JobliteWeb do
    pipe_through :browser

    post "/users/log-in", EmailAuthController, :login
    post "/users/log-in/verify", EmailAuthController, :verify
    post "/users/log-in/resend", EmailAuthController, :resend
    post "/users/sign-up", EmailAuthController, :signup
    post "/users/recover", EmailAuthController, :recover
    delete "/users/log-out", SessionController, :delete
  end

  live_session :public,
    on_mount: [
      {JobliteWeb.UserAuth, :mount_current_user},
      {JobliteWeb.UserAuth, :redirect_if_user_is_authenticated}
    ] do
    scope "/", JobliteWeb do
      pipe_through [:browser, :redirect_if_user_is_authenticated]

      live "/users/log-in", UserLoginLive, :login
      live "/users/recover", UserLoginLive, :recover
      live "/users/sign-up", UserSignupLive, :new
      live "/users/log-in/verify", UserVerifyLive, :new
    end
  end

  live_session :default,
    on_mount: [{JobliteWeb.UserAuth, :mount_current_user}] do
    scope "/", JobliteWeb do
      pipe_through [:browser]

      live "/", HomeLive
    end

    scope "/", JobliteWeb do
      pipe_through [:browser]

      live "/explore", ExploreLive
    end
  end

  live_session :protected,
    on_mount: [{JobliteWeb.UserAuth, :ensure_authenticated}] do
    scope "/", JobliteWeb do
      pipe_through [:browser]

      live "/account", AccountLive, :index
      live "/explore/saved", SavedBoardsLive
    end
  end
end
