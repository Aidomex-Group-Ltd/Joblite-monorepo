# syntax=docker/dockerfile:1
#
# Joblite product release images.
#
# Context MUST be the workspace parent that contains both sibling repositories
#   <workspace>/backend   (:joblite_core)
#   <workspace>/frontend  (:joblite_web, assembles the `joblite` release)
# Use backend/deploy/build-images.sh as the documented entry point.
#
# Targets:
#   backend   - one-off maintenance image (migrations etc.) over the release
#   liveview  - product image serving Phoenix + LiveView (default target)

ARG ELIXIR_IMAGE=hexpm/elixir:1.20.4-erlang-28.5.0.8-debian-bookworm-20261020-slim
ARG DEBIAN_IMAGE=debian:bookworm-slim

# ---------------------------------------------------------------------------
# build: compiles :joblite_core + :joblite_web and assembles the `joblite`
# release with MIX_ENV=prod. Never shipped; compilers stay out of runtime.
# ---------------------------------------------------------------------------
FROM ${ELIXIR_IMAGE} AS build

# build-essential compiles native libraries (bcrypt_elixir NIF via elixir_make).
# curl is used to pre-fetch the esbuild binary (see below).
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV MIX_ENV=prod LANG=C.UTF-8

# Dependency manifests first so the dependency layer caches across source edits.
# The frontend mix.lock is the integrated application's dependency resolution
# (Mix ignores a path dependency's own lockfile).
COPY backend/mix.exs backend/mix.lock backend/.formatter.exs ./backend/
COPY frontend/mix.exs frontend/mix.lock frontend/.formatter.exs ./frontend/

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app/frontend
RUN mix deps.get --only prod

# Pre-install the esbuild binary deterministically.
#
# `mix assets.deploy` would otherwise download esbuild at build time through
# the esbuild hex package's Erlang :httpc client. That fetch has no connect
# timeout and hangs indefinitely in some builders, stalling the image build
# at "Downloading esbuild from registry.npmjs.org". Fetch the same npm
# platform tarball with curl (which the builder handles reliably) and place
# the binary exactly where the esbuild package looks for it
# (_build/esbuild-linux-x64, see Esbuild.default_bin_path/0). esbuild then
# skips its own download because File.exists?(bin_path()) is already true.
ARG ESBUILD_VERSION=0.25.5
RUN mkdir -p /app/frontend/_build \
 && curl -fsSL "https://registry.npmjs.org/@esbuild/linux-x64/-/linux-x64-${ESBUILD_VERSION}.tgz" \
      -o /tmp/esbuild.tgz \
 && mkdir -p /tmp/esbuild-pkg \
 && tar -xzf /tmp/esbuild.tgz -C /tmp/esbuild-pkg \
 && cp /tmp/esbuild-pkg/package/bin/esbuild /app/frontend/_build/esbuild-linux-x64 \
 && chmod +x /app/frontend/_build/esbuild-linux-x64 \
 && rm -rf /tmp/esbuild.tgz /tmp/esbuild-pkg

# Full source of both applications, then compile, production assets and release.
# Absolute destinations matter here: WORKDIR is /app/frontend, so relative
# copies would land under /app/frontend/{backend,frontend} instead of the
# project roots that Mix and the sibling path dependency read.
COPY backend /app/backend
COPY frontend /app/frontend

RUN mix deps.compile \
 && mix compile \
 && mix assets.deploy \
 && mix release joblite

# ---------------------------------------------------------------------------
# runtime-base: the release artifact plus a minimal Debian userland.
# Non-root; no compilers, no source checkouts, no Mix.
# ---------------------------------------------------------------------------
FROM ${DEBIAN_IMAGE} AS runtime-base

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl libstdc++6 openssl \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --system --gid 10001 joblite \
 && useradd --system --uid 10001 --gid joblite --home-dir /app --shell /usr/sbin/nologin joblite

WORKDIR /app
COPY --from=build --chown=joblite:joblite /app/frontend/_build/prod/rel/joblite/ ./

ENV HOME=/app \
    LANG=C.UTF-8 \
    RELEASE_DISTRIBUTION=none
USER joblite

# ---------------------------------------------------------------------------
# backend: maintenance image. Same release artifact, never starts the HTTP
# endpoint (JOBLITE_ROLE=maintenance). Invoked as a one-off container, e.g.
#   docker run --rm joblite-backend:<id> eval 'JobliteWeb.Release.migrate()'
# ---------------------------------------------------------------------------
FROM runtime-base AS backend

ENV JOBLITE_ROLE=maintenance
ENTRYPOINT ["/app/bin/joblite"]
CMD ["help"]

# ---------------------------------------------------------------------------
# liveview: product image. Serves the Phoenix endpoint and LiveView WebSocket.
# ---------------------------------------------------------------------------
FROM runtime-base AS liveview

ENV PORT=4000
EXPOSE 4000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s \
  CMD curl -fsS "http://127.0.0.1:${PORT:-4000}/health/live" >/dev/null || exit 1
ENTRYPOINT ["/app/bin/joblite"]
CMD ["start"]
