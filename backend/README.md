# Joblite backend

OTP app: `:joblite_core`. Public domain namespace: `Joblite`.
This is the business and PostgreSQL side of one Phoenix monolith, not a standalone HTTP API.

Read `docs/DEVELOPMENT_HANDBOOK.md`, `docs/PHASES.md`, `docs/STATUS.md` and `AGENTS.md`.
The paired web repo must be a sibling at `../frontend`.

Start checks after installing the pinned runtime:

```bash
mix deps.get
mix format
mix test
elixir scripts/check_architecture.exs
```

Local development database and secrets (openssl-generated, gitignored):

```bash
docker compose up -d postgres     # 127.0.0.1:5543, database joblite_dev_db
scripts/generate_secrets.sh       # writes backend/secrets/dev.env and the sibling frontend's
mix ecto.migrate
```

Production image of the core (no HTTP endpoint, no port; the browser-facing
release is assembled by the sibling frontend repository):

```bash
docker build -t joblite-core:local .
docker run --rm -e DATABASE_URL=... joblite-core:local eval "Joblite.Release.migrate()"
docker run -d -e DATABASE_URL=... joblite-core:local
```

Deployment variables are documented in `deploy/README.md` and
`deploy/env.example`.

No dependency lockfile or executed Elixir test result is included yet. Core standalone
tests initially disable Repo startup. Follow P02 before adding database tests.
