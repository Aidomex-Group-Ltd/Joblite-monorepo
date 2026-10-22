# syntax=docker/dockerfile:1
#
# Joblite core (:joblite_core) production image.
#
# Build context: this repository's root.
#   docker build -t joblite-core:<tag> .
#
# What this repository is: the business core of the Joblite monolith. It owns
# the PostgreSQL repository, the PubSub and the migration ledger. It has no
# HTTP endpoint, no router and no port: the browser-facing Phoenix/LiveView
# endpoint lives in the sibling repository ../frontend and is assembled by
# backend/deploy/Dockerfile (build context: the workspace parent that holds
# both repositories). This image therefore runs the core release as a service:
# it boots the Repo and the PubSub and stays up; it serves no traffic.
#
# Runtime configuration (read from the environment, never baked into the image):
#   DATABASE_URL              required  PostgreSQL connection URL
#   DATABASE_SSL              optional  verify-full (default) | require | disable
#   DATABASE_CA_CERT          required by verify-full: CA bundle path in the image
#   DATABASE_SSL_SERVER_NAME  required by verify-full: expected certificate name
#   POOL_SIZE                 optional  Repo pool size (default 5)
#
# Migrations are never implicit. Apply them explicitly, once, before the
# service starts:
#   docker run --rm -e DATABASE_URL=... joblite-core:<tag> \
#     eval "Joblite.Release.migrate()"

ARG ELIXIR_IMAGE=hexpm/elixir:1.20.4-erlang-28.5.0.8-debian-bookworm-20261020-slim
ARG DEBIAN_IMAGE=debian:bookworm-slim

# ---------------------------------------------------------------------------
# build: compiles :joblite_core and assembles the release with MIX_ENV=prod.
# Compilers and the source checkout never reach the runtime image.
# ---------------------------------------------------------------------------
FROM ${ELIXIR_IMAGE} AS build

# build-essential compiles the bcrypt_elixir NIF (elixir_make).
RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV MIX_ENV=prod LANG=C.UTF-8

# Dependency manifests first, so the dependency layer caches across source
# edits. This repository's lockfile is the core dependency resolution.
COPY mix.exs mix.lock .formatter.exs ./
RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get --only prod

COPY config ./config
COPY lib ./lib
COPY priv ./priv

RUN mix deps.compile \
  && mix compile \
  && mix release joblite_core

# ---------------------------------------------------------------------------
# runtime: the release artifact over a minimal Debian userland.
# Non-root, no compilers, no source checkout, no Mix, no secrets.
# ---------------------------------------------------------------------------
FROM ${DEBIAN_IMAGE} AS runtime

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates libstdc++6 openssl \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd --system --gid 10001 joblite \
  && useradd --system --uid 10001 --gid joblite --home-dir /app --shell /usr/sbin/nologin joblite

WORKDIR /app
COPY --from=build --chown=joblite:joblite /app/_build/prod/rel/joblite_core/ ./

ENV HOME=/app \
    LANG=C.UTF-8 \
    RELEASE_DISTRIBUTION=sname \
    POOL_SIZE=5

USER joblite

# Readiness uses the core's own public boundary (Joblite.Health.readiness/1)
# through the release control command: the core exposes no HTTP route, so
# there is no port to probe. The comparison prints "true" only when the
# bounded readiness probe succeeded.
HEALTHCHECK --interval=15s --timeout=10s --start-period=20s \
  CMD /app/bin/joblite_core rpc 'IO.puts(Joblite.Health.readiness() == :ok)' | grep -qx true

ENTRYPOINT ["/app/bin/joblite_core"]
CMD ["start"]
