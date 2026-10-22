# Source and verification status

Date: 20 October 2026. Architecture revision: 2.0.

## Prepared

- Two source trees with separate Mix application identities and a sibling dependency.
- One-release definition, core Repo, PubSub, health boundary and frontend endpoint.
- Minimal connected LiveView teaching slice and pure application-stage rule examples.
- Core rule tests and a connected LiveView test (authored in the kit; executed and
  passing on the Linux host under P01).
- Development handbook, atomic phases, reusable prompt and handoff templates.
- Non-overwriting installer for the requested Linux layout.
- Two local Git repositories (initialized by the installing session on the host;
  the packaged kit itself contained no `.git` directories).

## Installed on the Linux host (20 October 2026, implementation session)

- `/home/aidomex/Joblite/backend` and `/home/aidomex/Joblite/frontend` populated from
  the extracted kit by a controlled copy (destinations verified empty first; the
  installer was inspected and not used because it refuses existing directories).
- Two independent Git roots on `main`, no parent repository, no remotes. Legacy
  `~/joblite-release` and `~/joblite-www` untouched.
- P00 evidence: `docs/iterations/P00.md`, `docs/ADR-0001-two-sibling-repos-one-release.md`,
  ledger `docs/IMPLEMENTATION_STATE.json`.
- Host toolchain present: Elixir 1.20.2/OTP 28 via asdf, PostgreSQL 14 client/server,
  Node 22. Exact runtime pin verification is P01.01.

## Verified on the Linux host (implementation session, 20 October 2026)

- P00 (workspace/ADR/docs/foundation): verified. Evidence `docs/iterations/P00.md`.
- P01.01 pinned runtime: Elixir 1.20.4-otp-28 / Erlang 28.5 execute in both repos
  (installed the missing Elixir pin via asdf).
- P01.02 backend: real `mix.lock` (ecto_sql 3.14.0, ecto 3.14.2, postgrex 0.22.4,
  phoenix_pubsub 2.4.1); format/compile-with-warnings-as-errors/3 tests/`mix check`
  pass. Fixed the `check` alias env (`def cli` preferred_envs) exposed by Elixir 1.20.
- P01.03 frontend: real `mix.lock` (phoenix 1.8.16, phoenix_live_view 1.2.13,
  bandit 1.13.1, plug 1.20.3 + core path dep); format/compile/tests/`mix check` pass.
- P01.04 assets and connected UI: esbuild bundle built; headless-Chromium smoke
  (`frontend/scripts/browser_smoke.js`) proves LiveView WebSocket join, a working
  `phx-click` event and liveness; `/health/ready` correctly 503 without a database.
- P01.05 quality gates: Credo (both repos, 0 issues) wired into `mix check`;
  Sobelow 1 reviewed low-confidence finding (`Config.CSWH`, check_origin set in
  config); architecture smoke passes.
- P01.06 release: `MIX_ENV=prod mix release joblite` assembled one artifact
  containing core+web+digested assets, no sibling source paths in release config;
  `bin/joblite version` runs. Production boot remains a P11 gate.
- Compatible commits: backend `49510b1`, frontend `ca33fb6`. Full evidence:
  `docs/iterations/P01.md`.

## Verified on the Linux host (implementation session, 20 October 2026, continued)

- P02.01 databases: isolated postgres:18 on `127.0.0.1:5543` (host PostgreSQL 14
  owns 5432; `fsync=off` documented for this local-only volume after its first
  init stalled >220s and was recreated empty). `joblite_dev` + `joblite_test`
  exist; migration ledger empty (`schema_migrations`, 0 rows).
- P02.02 Sandbox helpers: Repo starts in all envs; `:manual` Sandbox mode;
  `Joblite.DataCase` (backend) and `JobliteWeb.ConnCase` (frontend) own
  connections per test; tests prove `current_database()=joblite_test`,
  ownership denial and `allow_runner` allowance.
- P02.03 readiness: `readiness/1` failure mapping tested (missing repo,
  unreachable port); live smoke `/health/live` 200, `/health/ready` 200 with DB
  (was 503 in P01), `/` 200; liveness independent of the database.
- P02.04 conventions: handbook §8 documents empty forward-only ledger, UUID
  PK/FK defaults from `config/shared.exs`, UTC timestamps, Sandbox rollback,
  composite FKs for tenant consistency; no speculative tables.
- Compatible commits: backend `1a34aa7`, frontend `e73633c`. Full evidence:
  `docs/iterations/P02.md`.

## Verified on the Linux host (implementation session, 20 October 2026, continued)

- P03.01 accounts foundation: first real migration
  (`20261020164000`, users + users_tokens, UUID PKs, unique lowercase email,
  FK delete_all, UTC timestamps); `Joblite.Accounts` core-only context
  (register/normalize/hash, session-token generate/verify/revoke with 60-day
  validity, hash-only storage); bcrypt_elixir 3.3.2 in core (+ frontend
  transitive lockfile); 11 new tests; 21 backend + 2 frontend tests pass.
- Compatible commits: backend `9431800`, frontend `93819b0`. Full evidence:
  `docs/iterations/P03.md`.

## Verified on the Linux host (implementation session, 20 October 2026, continued)

- P03.02 authentication: core `authenticate_by_email_password/2`
  (timing-equalized failures); web `UserAuth` plug + on_mount hooks,
  `SessionController` login/logout with session renew+clear, `UserLoginLive`,
  protected `AccountLive`, auth-aware layout nav; revoked/expired tokens
  rejected on reconnect; 25 backend + 15 frontend tests; live curl journey
  verified end-to-end.
- Compatible commits: backend `e503d31`, frontend `1e25122`. Full evidence:
  `docs/iterations/P03.md`.

## Frontend feed preview integration (21 October 2026, integration session)

- The approved X-style mobile feed preview (`Joblite-Feed-Integration` package)
  is integrated into the frontend working tree at `live "/", HomeLive`:
  thumbnail-first feed, tabs/pages, like/save, mixed-media composer with
  browser-local media, native full-viewport media viewer, session-only state.
  No backend context, schema, migration, dependency or router change; no
  durable posts or uploads. Uncommitted, user-owned frontend work.
- Verified on this host: backend `mix check` 25/25; frontend `mix check` 26/26
  (includes 14 feed tests) with Credo clean; `mix assets.build` ok; live server
  smoke plus Playwright checks (deferred video loading, viewer lifecycle,
  filters, composer post, 320 px layout, no console errors). Durable
  `Joblite.Feed`/`Joblite.Media` remain gated on P03.03–P03.04 per PHASES.md
  and the package WORKFLOW §7–§8. Audit, plan, test plan and evidence:
  `programs/ahis-unified-atomic/reports/feed-integration/` at the workspace root.

## Verified on the Linux host (implementation session, 21 October 2026, deployment increment)

- P11.05 repository-root image: `backend/Dockerfile` builds the `:joblite_core`
  release from this repository alone (multi-stage, non-root, 40.8 MB, no source
  checkout and no secret in the image). The core is a service, not a web
  service: no router, no endpoint, no port; the browser-facing release stays
  the sibling frontend's `deploy/Dockerfile` (context = workspace parent).
  Runtime configuration is environment-only (`DATABASE_URL`, `DATABASE_SSL`,
  `DATABASE_CA_CERT`, `DATABASE_SSL_SERVER_NAME`, `POOL_SIZE`); migrations stay
  explicit through `Joblite.Release.migrate/0`.
- P11.06 development database and secrets: `joblite_dev_db` created on
  `127.0.0.1:5543` with the documented local-only credentials (the old
  `joblite_dev` database is untouched); `scripts/generate_secrets.sh` generates
  `JWT_SECRET`, `SECRET_KEY_BASE` and `LIVE_SIGNING_SALT` with openssl into
  gitignored files loaded by `config/secrets.exs` in `:dev` only.
- Verified on this host: image build pass; migration command pass; container
  `healthy` with a reachable database and `unhealthy` with an unreachable one;
  no dev secret inside the image; `postgresql://` URL form accepted. The
  supplied Supabase host was unreachable from this host, so no claim is made
  about that database. Evidence: `docs/iterations/P11.md`.

## Global job board intelligence directory (21 October 2026, integration session)

- A source registry of nine known job boards with the permission decision that
  governs each one: `permitted_live_aggregation` (Remote OK, Jobicy), 
  `permission_pending` (Himalayas) and `directory_only` (Remotive, We Work
  Remotely, Working Nomads, JobGet, Arbeitnow, No Fluff Jobs). A board whose
  published terms allow republication may be imported with attribution and a
  canonical link; every other board stays an outbound link. The terms behind
  each decision were read on 21 October 2026 and are recorded per row.
- Core context `Joblite.JobBoards` owns the registry, the per-account saved and
  dismissed state, the feed discovery cards and the import pass. Three
  migrations: the registry tables, the nine-row seed and the import error
  column.
- Web surfaces: `/explore` (the directory with its filters), `/explore/saved`
  (the boards of the account) and one labelled discovery card in the feed that
  links out to the board. The card rotates with the visit counter of the
  browser session. The session token stays in `socket.private` and is
  re-resolved for every save, remove and dismiss event.
- Verified on this host: backend `mix test` 69/69, `mix format --check-formatted`,
  `mix compile --warnings-as-errors`, `mix credo` (0 issues) and
  `scripts/check_architecture.exs`; frontend `mix test` 45/45 with the same
  format/compile/credo gates. Uncommitted in both repositories; backend HEAD
  `f090eb6`, frontend HEAD `5390cd1`. Evidence: `docs/iterations/P12.md`.
- Not established: no worker runs the import pass and the `:httpc` transport
  was not exercised against a live board endpoint; the application itself
  contacted no third-party board.

## Not established

- Organizations, memberships, tenant scope and authorization regression cases
  (P03.03-P03.04).
- Tenant isolation, ATS persistence, AI behavior or production readiness.
- Release boot with real runtime credentials (P11 gate).
- Any connection to the Supabase instance named in the deployment request: the
  host is unreachable from this machine.
- GitHub remotes or published repositories.

## Next actions

1. ~~Install safely on the intended host; verify the two Git roots and preserve legacy files.~~ Done; see `docs/iterations/P00.md`.
2. ~~Complete P01.01: verify the pinned toolchain can execute.~~ Done.
3. ~~Resolve dependencies, format, compile and execute the authored tests under P01.~~ Done.
4. ~~Record actual command results and compatible commits before marking any phase verified.~~ Done for P00/P01.
5. ~~P02.01: create isolated development and test databases.~~ Done; port 5543
   chosen with evidence; see `docs/iterations/P02.md`.
6. ~~P03.01: Accounts schema, identity lookup and session token lifecycle.~~
   Done; see `docs/iterations/P03.md`.
7. ~~P03.02: login/logout and LiveView authentication integration.~~ Done;
   see `docs/iterations/P03.md`.
8. P03.03: Organizations, memberships and scoped roles. Two seeded
   organizations; candidate global identity and organization-specific role
   are distinct.
9. P11 deployment increment: the repository-root core image is built and
   verified; the product web service still deploys from the assembled
   monorepo. Done; see `docs/iterations/P11.md`.
10. Job board directory increment: the registry, the directory page, the feed
    discovery card and the saved boards view are built and verified. Done; see
    `docs/iterations/P12.md`. Open inside it: the worker that calls
    `sync_source/2` within the permitted interval, and the preference screen
    that writes the account's discovery preferences.

The ledger `docs/IMPLEMENTATION_STATE.json` follows the atoms of
`docs/PHASES.md`. The deployment and job board increments are recorded as
iteration evidence (`docs/iterations/P11.md`, `docs/iterations/P12.md`) and in
this status file.

See VALIDATION.md for packaging/static checks completed in the authoring session.
