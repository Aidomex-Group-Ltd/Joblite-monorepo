defmodule JobliteWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :joblite_web

  @session_options [
    store: :cookie,
    key: "_joblite_session",
    signing_salt: "joblite-session-v1",
    same_site: "Lax",
    http_only: true,
    secure: Application.compile_env(:joblite_web, :secure_cookies, false)
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug Plug.Static, at: "/", from: :joblite_web, gzip: false, only: ~w(assets uploads)
  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug JobliteWeb.Router
end
