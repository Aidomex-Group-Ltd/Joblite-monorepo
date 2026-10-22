import Config
# secrets.exs loads the gitignored development secrets and exports them as
# environment variables; shared.exs reads DATABASE_URL from the environment.
import_config "../../backend/config/secrets.exs"
import_config "../../backend/config/shared.exs"

config :phoenix, :json_library, Jason
config :swoosh, :api_client, JobliteWeb.NoopApiClient
config :joblite_web, :secure_cookies, config_env() == :prod

# Development and test keep sign-in codes in the local Swoosh mailbox. Production
# overrides this in runtime.exs with SMTP settings from the environment.
config :joblite_web, JobliteWeb.Mailer, adapter: Swoosh.Adapters.Local

config :joblite_web, JobliteWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  pubsub_server: Joblite.PubSub,
  render_errors: [formats: [html: JobliteWeb.ErrorHTML], layout: false],
  live_view: [signing_salt: System.get_env("LIVE_SIGNING_SALT") || "joblite-live-v1"]

config :esbuild,
  version: "0.25.5",
  default: [
    args: ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

import_config "#{config_env()}.exs"
