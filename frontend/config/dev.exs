import Config

config :joblite_web, JobliteWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: System.get_env("SECRET_KEY_BASE") || String.duplicate("development-only-", 8),
  code_reloader: false,
  debug_errors: true,
  check_origin: true,
  watchers: [esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}]
