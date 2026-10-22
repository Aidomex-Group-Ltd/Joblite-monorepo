import Config

config :joblite_web, JobliteWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: String.duplicate("test-only-", 10),
  server: false

config :phoenix, :plug_init_mode, :runtime
config :logger, level: :warning
