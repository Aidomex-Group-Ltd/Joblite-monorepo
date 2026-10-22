import Config
# secrets.exs runs first: it exports the gitignored development secrets, and
# shared.exs reads DATABASE_URL from the environment.
import_config "secrets.exs"
import_config "shared.exs"

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
