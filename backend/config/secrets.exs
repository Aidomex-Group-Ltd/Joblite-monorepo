import Config

# Local development secrets loader.
#
# Secret values never live in tracked source. They are generated with openssl
# by `scripts/generate_secrets.sh` into gitignored files:
#
#   backend/secrets/dev.env    DATABASE_URL, JWT_SECRET
#   frontend/secrets/dev.env   SECRET_KEY_BASE, LIVE_SIGNING_SALT
#
# Only the :dev environment reads these files. Production reads real
# environment variables through frontend/config/runtime.exs; the test
# environment keeps the deterministic values in frontend/config/test.exs.
#
# The file format is one KEY=VALUE per line. Blank lines and lines starting
# with '#' are ignored.

parse_env = fn path ->
  case File.read(path) do
    {:ok, content} ->
      content
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
      |> Enum.flat_map(fn line ->
        case String.split(line, "=", parts: 2) do
          [key, value] -> [{String.trim(key), String.trim(value)}]
          _ -> []
        end
      end)
      |> Map.new()

    {:error, :enoent} ->
      %{}

    {:error, reason} ->
      raise "cannot read secrets file #{path}: #{inspect(reason)}"
  end
end

if config_env() == :dev do
  backend_env = Path.expand("../secrets/dev.env", __DIR__)
  frontend_env = Path.expand("../../frontend/secrets/dev.env", __DIR__)

  secrets =
    parse_env.(backend_env)
    |> Map.merge(parse_env.(frontend_env))

  # Exporting the values makes them visible to the rest of the configuration
  # (the Repo URL) and to the running application.
  Enum.each(secrets, fn {key, value} -> System.put_env(key, value) end)

  if jwt_secret = secrets["JWT_SECRET"] do
    # The JWT signing secret belongs to the core application: call sites read
    # it from the application environment instead of accepting it per request.
    config :joblite_core, :jwt_secret, jwt_secret
  end
end
