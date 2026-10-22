import Config

if config_env() == :prod do
  # Sign-in codes are delivered by SMTP. The relay defaults to localhost so a
  # deployment without mail settings still boots and reports a delivery error
  # instead of silently pretending a code was sent. Set the SMTP_* variables
  # and MAIL_FROM for a working deployment.
  smtp_credentials =
    case {System.get_env("SMTP_USERNAME"), System.get_env("SMTP_PASSWORD")} do
      {username, password} when is_binary(username) and is_binary(password) ->
        [username: username, password: password]

      _ ->
        [auth: "never"]
    end

  config :joblite_web,
         JobliteWeb.Mailer,
         [
           adapter: Swoosh.Adapters.SMTP,
           relay: System.get_env("SMTP_HOST", "localhost"),
           port: System.get_env("SMTP_PORT", "587"),
           tls: System.get_env("SMTP_TLS", "always"),
           ssl: System.get_env("SMTP_SSL", "false")
         ] ++ smtp_credentials

  # DATABASE_SSL selects the PostgreSQL transport policy. The default
  # `require` keeps the connection encrypted without certificate pinning,
  # which is the only usable mode on managed platforms that terminate
  # database TLS without shipping a CA file (Render managed PostgreSQL).
  # `verify-full` adds pinning against a CA bundle that must exist inside
  # the container: a missing file fails the boot here, with the variable
  # named, instead of looping on connection errors. An unknown value fails
  # the boot too: nothing is ever silently downgraded.
  database_ssl =
    case System.get_env("DATABASE_SSL", "require") do
      "verify-full" ->
        ca_cert = System.fetch_env!("DATABASE_CA_CERT")

        unless File.regular?(ca_cert) do
          raise "DATABASE_CA_CERT points to #{inspect(ca_cert)}, which does not exist " <>
                  "in this container; mount the bundle as a secret file, or use " <>
                  "DATABASE_SSL=require on a platform that ships no CA file"
        end

        [
          verify: :verify_peer,
          cacertfile: ca_cert,
          server_name_indication:
            String.to_charlist(System.fetch_env!("DATABASE_SSL_SERVER_NAME"))
        ]

      "require" ->
        [verify: :verify_none]

      "disable" ->
        false

      other ->
        raise "unsupported DATABASE_SSL value: #{inspect(other)} " <>
                "(expected verify-full | require | disable)"
    end

  config :joblite_core, Joblite.Repo,
    url: System.fetch_env!("DATABASE_URL"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE", "5")),
    ssl: database_ssl

  # The one-off maintenance image (joblite-backend) sets JOBLITE_ROLE=maintenance:
  # it runs release commands such as migrations and never boots the endpoint, so
  # endpoint-only secrets (PHX_HOST, SECRET_KEY_BASE, PORT) are demanded from the
  # web role alone. Production deployments never set this variable on the web tier.
  if System.get_env("JOBLITE_ROLE", "web") != "maintenance" do
    host = System.fetch_env!("PHX_HOST")

    config :joblite_web, JobliteWeb.Endpoint,
      server: true,
      url: [scheme: "https", host: host, port: 443],
      http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4000"))],
      check_origin: ["https://#{host}"],
      secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
  end
end
