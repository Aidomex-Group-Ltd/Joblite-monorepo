# Joblite Docker release and deployment

One release image pair, built from the workspace parent that holds both
sibling repositories (`../backend` = `:joblite_core`, `../frontend` =
`:joblite_web`, which assembles the `joblite` release). Everything here is
driven from the backend repository; nothing is committed or published by
these scripts.

## Files

| File | Responsibility |
|---|---|
| `../Dockerfile` | Repository-root image of the core application (`:joblite_core`), built from this repository alone. |
| `Dockerfile` | Multi-stage build: `liveview` (product) and `backend` (one-off maintenance, migrations) targets over the same release. |
| `Dockerfile.dockerignore` | Build-context filter next to the Dockerfile (copied to `.dockerignore` at the monorepo root for Render). |
| `build-images.sh` | Local build entry point; tags both images with a recorded build id. |
| `compose.yaml` | Isolated local verification stack: private TLS PostgreSQL, explicit migration, app, local HTTPS proxy. |
| `certs.sh`, `nginx/local.conf` | Local-only certificates and TLS termination for the verification stack. |
| `env.example` | Runtime configuration reference (`DATABASE_SSL`, endpoint, secrets). |
| `render.yaml` | Render blueprint: web service + database + explicit migration job. |
| `assemble-monorepo.sh` | Produces the single git repository Render needs (see below). |

## Two images, two repositories

| Image | Build context | Contents | Serves HTTP |
|---|---|---|---|
| `../Dockerfile` | this repository (backend) | `:joblite_core` release | no |
| `Dockerfile` | workspace parent (backend + frontend) | `joblite` release (core + web) | yes |

The core repository is the business and database side of the monolith: it has
no router, no endpoint and no port. `./Dockerfile` at the repository root
therefore builds the core release as a service (Repo + PubSub, no listener),
and the browser-facing service stays the assembled `joblite` release.

### Core image (`../Dockerfile`)

```bash
cd backend
docker build -t joblite-core:<tag> .
docker run --rm -e DATABASE_URL=... joblite-core:<tag> eval "Joblite.Release.migrate()"
docker run -d -e DATABASE_URL=... joblite-core:<tag>
```

Runtime configuration (environment only; nothing is baked into the image):

| Variable | Required | Meaning |
|---|---|---|
| `DATABASE_URL` | yes | PostgreSQL connection URL. |
| `DATABASE_SSL` | no | `require` (default), `verify-full` or `disable`. |
| `DATABASE_CA_CERT` | with `verify-full` | CA bundle path; `require` needs none. |
| `DATABASE_SSL_SERVER_NAME` | with `verify-full` | expected certificate name. |
| `POOL_SIZE` | no | Repo pool size (default 5). |
| `RELEASE_NODE` | no | node name; set it when several containers share one hostname. |

There is no `PORT`, no `PHX_HOST` and no `SECRET_KEY_BASE`: the core serves
no traffic and signs no session. Readiness is the core's own bounded probe
(`Joblite.Health.readiness/1`) executed through the release control command,
which is what the image's `HEALTHCHECK` does.

## Local verification (no external accounts)

```bash
cd backend/deploy
./build-images.sh                       # prints JOBLITE_BUILD_ID
export JOBLITE_BUILD_ID=<id>
cp env.example .env                     # fill in SECRET_KEY_BASE only
docker compose up -d db certs
docker compose --profile ops run --rm migrate eval 'JobliteWeb.Release.migrate()'
docker compose up -d
curl -k https://localhost/health/ready  # through the local TLS proxy
docker compose down                      # keep volumes
```

Migrations are never started by `docker compose up`; they run only through
the explicit `migrate` command, which is the same maintenance image Render
uses.

## Deploying to Render

Render builds one Dockerfile from one git repository; the build context for
this release is the workspace parent, so the two repositories are assembled
into one pushable repository first:

```bash
# both repos must be committed; the export is taken from each HEAD
./backend/deploy/assemble-monorepo.sh
# → ../joblite-monorepo  (render.yaml, .dockerignore and Dockerfile at the root)
```

The assembled repository carries the product Dockerfile at its root as
`./Dockerfile` (the same file as `backend/deploy/Dockerfile`), so a builder
that defaults to `./Dockerfile` finds it; the blueprint below keeps the
explicit path.

1. Push `joblite-monorepo` to your git host and connect it in Render as a
   **Blueprint** (Render reads `render.yaml` at the repository root). Edit
   `PHX_HOST` in that file first: it must be the public hostname of the web
   service and it drives https URLs, secure cookies and the LiveView
   WebSocket origin check.
2. The blueprint creates the `joblite` web service (the final stage of the
   Dockerfile, `liveview`; health check `/health/live`) but no Render
   PostgreSQL database. The production database is the existing Aiven
   PostgreSQL instance (`pg-2855ae63-joblite.k.aivencloud.com` /
   `defaultdb`). Set `DATABASE_URL` as a Render secret (`sync: false` in
   `render.yaml`); never commit the connection string. Keep
   `DATABASE_SSL=require` unless a stable Aiven CA bundle is mounted and
   `verify-full` with `DATABASE_CA_CERT`/`DATABASE_SSL_SERVER_NAME` is used.
3. Apply migrations explicitly as a one-off job created from the `joblite`
   service (Render dashboard → Run Job), or from Render Shell in the web
   instance:

   ```bash
   /app/bin/joblite eval 'JobliteWeb.Release.migrate()'
   ```

   Until then `/health/ready` returns 503 while `/health/live` stays 200 —
   that split is intentional.
4. `SECRET_KEY_BASE` is generated by the blueprint. `PORT` is assigned by
   Render and read by the release; never hardcode it. TLS terminates at
   Render's edge; the release only rewrites on `X-Forwarded-Proto`.

Notes and limits:

- Free-tier web services spin down when idle and free PostgreSQL instances
  expire; adjust `plan:` in `render.yaml` as needed.
- On paid plans you may additionally set
  `preDeployCommand: /app/bin/joblite eval 'JobliteWeb.Release.migrate()'`
  on the web service so every deploy is gated on the migration step; the
  explicit job remains the portable default.
- Custom domains: add them in Render and point `PHX_HOST` at the domain in
  use.
- Never commit `.env`, certificates or real candidate data; secrets are
  runtime configuration only.
