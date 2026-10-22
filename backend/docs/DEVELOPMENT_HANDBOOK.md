# Joblite AHIS: Phoenix and LiveView development handbook

**Architecture revision:** 2.0, 20 October 2026.  
**Target workspace:** `/home/aidomex/Joblite`.  
**Source repositories:** `backend` and `frontend`, independently versioned.  
**Runtime:** a modular monolith assembled into one Elixir release.  
**Database:** PostgreSQL, accessed through one Ecto Repo.

This architecture replaces the previous Phoenix API plus React proposal. The older assessment remains useful for legacy risks; its React, REST client and separate API deployment recommendations are superseded. Existing feature completeness and production state remain unverified.

## 1. Decisions that govern the implementation

1. Use Elixir, Phoenix, LiveView, HEEx and PostgreSQL. Small JavaScript hooks and CSS support browser behavior; React, a second UI framework and a SPA state store are excluded.
2. Maintain two source repositories at the requested paths. Do not create a Git repository at their parent. Do not use a remote API between these repositories.
3. `backend` is the OTP application `:joblite_core`, with business modules under `Joblite.*`. It owns domain rules, Ecto schemas/migrations, the Repo and background work.
4. `frontend` is `:joblite_web`, with modules under `JobliteWeb.*`. It owns routes, sessions at the transport boundary, LiveViews, HEEx, components and release assembly.
5. The frontend declares `{:joblite_core, path: "../backend", env: Mix.env()}`. They run in the same BEAM instance. This is a multi-application monolith, not a pair of independently deployed services.
6. Release assembly happens in `frontend`: `MIX_ENV=prod mix release joblite`. That artifact includes core, web and dependencies. It must boot without either source repository on the target machine.
7. Only backend modules access PostgreSQL. There is one `Joblite.Repo`; frontend code calls public context functions.
8. Human recruiters control hiring decisions and approve outgoing recruitment communications. AHIS initially automates bounded processing and internal tasks.
9. Small cohesive modules and explicit failures take precedence over architectural fashion. Add a layer only when its responsibility can be named and its benefit demonstrated.

Mix supports sibling path dependencies, but a dependency's lockfile is ignored by the parent project. Therefore the frontend lockfile resolves the assembled product, while the backend lockfile serves its standalone checks. Pair source commits explicitly; the path dependency does not pin a backend commit. [Mix dependency documentation](https://mix.hexdocs.pm/Mix.Tasks.Deps.html)

## 2. Architecture and dependency direction

```text
Browser: Phoenix LiveView client + HTML/CSS
                   |
                   v
frontend / :joblite_web
Router -> session/on_mount -> LiveView -> HEEx/function components
                                |
                    ordinary Elixir function call
                                v
backend / :joblite_core
Public context -> authorization -> use case -> rules + queries + Ecto.Multi
                                              |
                                         Joblite.Repo
                                              |
                                          PostgreSQL

Future side effects: backend worker -> provider behaviour -> concrete adapter
```

The frontend depends on core. Core never depends on `JobliteWeb`, a LiveView, a socket or `Plug.Conn`. `Phoenix.PubSub` is permitted as a standalone messaging dependency; HTTP/rendering dependencies are not. UI components receive already-authorized display data. A module named `Service` is not required between every pair of functions.

The supervision trees are `Joblite.Supervisor` for Repo/PubSub and `JobliteWeb.Supervisor` for the Endpoint. Two OTP supervisors in one release do not make two services. Add processes for concurrency, isolation or lifecycle management, not as substitutes for ordinary function calls.

Phoenix contexts provide a natural public boundary for domain/data operations. Internal query and use-case modules should remain private by convention to their owning context. [Phoenix contexts](https://phoenix.hexdocs.pm/contexts.html)

## 3. Repository layout and file ownership

```text
/home/aidomex/Joblite/                 # workspace, not a third repository
  backend/                           # Git repo A
    mix.exs                          # :joblite_core
    Dockerfile                       # core release image (this repository only)
    .dockerignore                    # build-context filter for that image
    config/config.exs
    config/shared.exs                # shared compile-time Repo settings
    config/secrets.exs               # dev-only loader for gitignored secrets
    config/runtime.exs               # production composition root of the core release
    lib/joblite/
      application.ex
      repo.ex
      health.ex
      release.ex                     # core-owned migration command
      hiring/stage.ex                # included pure-rule teaching slice
    priv/repo/migrations/
    secrets/dev.env.example          # tracked template for the gitignored file
    test/joblite/hiring/stage_test.exs
    scripts/check_architecture.exs
    scripts/generate_secrets.sh      # openssl generator for local secrets
    docs/                            # canonical architecture/process documentation
    compose.yaml                     # local PostgreSQL only
  frontend/                          # Git repo B
    mix.exs                          # :joblite_web; depends on ../backend
    config/config.exs                # imports core compile-time settings
    config/{dev,test,prod}.exs
    config/runtime.exs               # production composition root
    lib/joblite_web/
      application.ex
      endpoint.ex
      router.ex
      controllers/
      components/layouts/
      live/home_live.ex
      live/home_live/render.html.heex
      release.ex
    assets/{js,css}/
    test/joblite_web/
    docs/FRONTEND_GUIDE.md
```

Create feature directories only when implementing that feature. The anticipated domains are Accounts, Organizations, Candidates, Hiring, Intelligence, Scheduling, Notifications and Audit. Do not generate dozens of empty contexts at foundation time.

| Concern | Source owner | Rule |
|---|---|---|
| Business rules and authorization | backend | Every entry point, including workers, applies the same rules. |
| Schemas, queries and migrations | backend | Frontend does not import `Ecto.Query` or call Repo. |
| Browser sessions, plugs and mount hooks | frontend | Delegate identity lookup and resource authorization to core. |
| UI forms and navigation state | frontend | UI state does not become authoritative business state. |
| Provider credentials and deployment environment | frontend runtime composition root | Configure core at startup; keep credentials out of source and compile artifacts. |
| Production database configuration | frontend `config/runtime.exs` | It configures core's Repo as part of assembling the product. No runtime import of files outside the release. |
| Canonical development documentation | backend/docs | Frontend links to it; avoid drifting copies of policy. |
| Product compatibility and release manifest | frontend | Record both repo SHAs, locks and migrations. |

The backend's config files are not automatically loaded when it is a dependency. Frontend explicitly imports `shared.exs` at build time. Production runtime configuration is entirely inside frontend's runtime file so the release has no reference to `/home/aidomex/Joblite/backend` at boot.

## 4. Functional application of SOLID, GRASP and related principles

Elixir does not use class inheritance as its central design model. Apply the intent of OOP principles using functions, modules, immutable data and explicit contracts. Do not reproduce Java-style class hierarchies or create a GenServer for every entity.

| Principle | Joblite interpretation | Review evidence |
|---|---|---|
| SRP | A module has one coherent responsibility and a clear reason to change. | Stage rules are separate from authorization, SQL and notification delivery. |
| Open/closed | Keep stable workflows extensible through real variation points. | A second AI/email adapter can satisfy a small behaviour without changing hiring rules. |
| Liskov substitution | Every implementation preserves its behaviour's input, output, error and side-effect contract. | Shared contract tests run against fake and real adapter boundaries. |
| Interface segregation | Expose the smallest useful operations to each caller. | An assessment adapter cannot also send offers or modify memberships. |
| Dependency inversion | Policy depends on an explicit provider contract where a real external boundary exists. | Tests substitute an adapter without mocking the whole domain. |
| GRASP information expert | Put a rule where the information to enforce it lives. | Stage rules own transitions; membership policies own organization access. |
| GRASP creator | The owning context creates its entities and checks their invariants. | LiveView cannot create application structs and insert them directly. |
| GRASP controller | A context/use case coordinates a system operation. | LiveView translates events; it does not orchestrate multi-record transactions. |
| GRASP low coupling / high cohesion | Depend on context APIs and keep related rules together. | Core does not know UI details; unrelated domains are not collected in one utility file. |
| GRASP polymorphism / protected variations | Isolate provider differences with behaviours when needed. | Provider quirks do not leak into the recruiter workflow. |
| GRASP indirection / pure fabrication | Add coordination modules only when they remove concrete coupling. | A transaction coordinator has an identifiable responsibility and tests. |
| KISS | Choose the simplest design that satisfies current constraints. | One Repo, one release and normal function calls. |
| DRY | Keep one authoritative expression of a business rule. | One stage graph; no independent JS version of the same rule. |
| YAGNI | Implement today's validated use case. | No billing engine, event-sourcing framework or provider registry before needed. |
| Separation of concerns | Distinguish presentation, rules, persistence and effects. | Each part can be located and tested independently. |
| Encapsulation / least knowledge | Call a context rather than traversing other contexts' internals. | Hiring asks Organizations for membership decisions, not private query helpers. |
| Composition over inheritance | Compose small functions and provider contracts. | No artificial base-service framework or generic CRUD superclass. |
| Fail fast / explicit errors | Reject invalid input and missing required configuration clearly. | Domain failures are tagged results; misconfiguration cannot look healthy. |
| Secure defaults / least privilege | Deny access unless scope and resource policy authorize it. | Cross-tenant negative tests cover HTTP, mounts, events and jobs. |

Principles are tools with tradeoffs, not a requirement to add every pattern. Do not extract similar-looking code until it represents the same knowledge. Prefer a little duplication over a misleading abstraction. `@spec` documents contracts but does not enforce them at runtime. Behaviours define callbacks; they do not prove semantic substitutability. [Elixir typespecs](https://elixir.hexdocs.pm/typespecs.html)

## 5. Code size and module standards

Default authored module/template target: **50-200 lines**. Review at **more than 250 lines**. The included architecture smoke script fails `lib` source/templates above **400 lines**. These are project rules, not universal Elixir limits.

Aim for functions that fit on one screen, usually 5-25 lines; review functions above roughly 40 lines for mixed responsibilities. Do not split a clear function merely to meet a number. Never evade limits with compressed one-line code. Generated code is reviewed too; a documented exception requires a reason and a follow-up, rather than an automatic permanent exemption.

Use one primary module per file. Name modules after responsibilities: `Hiring.Stage`, `Hiring.Queries.Applications`, `Hiring.SubmitApplication`, `Intelligence.AssessmentWorker`. Avoid `Utils`, `Common`, `Manager`, `BaseService` and vague catch-all modules. A context facade delegates once cohesive implementation warrants extraction; it should not become a thousand-line file or a collection of meaningless wrappers.

Use module docs for responsibilities, public `@doc`/`@spec` for contracts, and comments for reasoning. Show normal and failure results. Prefer `{:ok, value}` and meaningful tagged errors over boolean ambiguity. Do not blanket-rescue and return success. Do not convert user strings into arbitrary atoms. Do not return raw exception messages, SQL or provider credentials to a browser.

The included `scripts/check_architecture.exs` is a fast textual smoke check for selected dependencies and file sizes. It can miss aliases, metaprogramming and architectural violations. It complements source review and compiler tooling; it is not proof of isolation or code quality.

## 6. Layer-by-layer implementation contract

Build the foundations in order: repository/toolchain wiring, database lifecycle, identity/tenancy, then business features. Within a feature, implement a thin vertical slice in this sequence:

1. State the observable behavior, actor, scope and invariant.
2. Define the public context function's input, output and error cases.
3. Add the smallest schema/constraint migration if persistence is required.
4. Implement pure domain rules and policy checks.
5. Implement queries and the transaction/use case behind the context boundary.
6. Add meaningful domain/persistence/authorization tests.
7. Implement the LiveView's state and event handling; reuse function components.
8. Add HEEx and accessibility behavior, followed by connected LiveView tests.
9. Add a background effect only when the stored business event is correct.
10. Run checks, update docs/status, and explain the source trace before marking the atom done.

Do not spend weeks completing every possible schema before delivering a working screen. Foundation dependencies are layered; feature delivery stays vertical. The exact atoms and their prerequisites are in `PHASES.md`.

## 7. Context and LiveView responsibilities

A future public operation might be `Hiring.submit_application(scope, job_id, attrs)`. `scope` is constructed from authenticated server state and active membership, never trusted from hidden inputs. The context checks the published job, candidate ownership, eligibility and application uniqueness, then commits an immutable input version, application, audit record and required task.

In a LiveView, `mount/3` initializes an authorized page and event handlers parse user input, call contexts and map results to form errors or display state. No SQL, provider HTTP request or business transaction belongs in a callback. Every event must reauthorize the requested action; a mounted page can outlive a revoked membership. LiveView's disconnected HTTP and connected lifecycle both need session validation. [LiveView security model](https://phoenix-live-view.hexdocs.pm/security-model.html)

Use function components for reusable markup with explicit attributes/slots. Use a LiveComponent when a UI unit truly needs its own state/events, not merely because markup is reusable. Keep `mount`, `handle_params`, `handle_event` and `handle_info` focused. Use streams and bounded queries for lists; do not load all candidates into assigns. Trigger browser hooks only for capabilities that cannot be expressed adequately with LiveView. [Phoenix.Component](https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html)

Subscribe to authorized PubSub topics only on connected mount. Reconcile from authoritative storage after reconnect; a message is a notification to refresh, not permission to view an object. Slow AI calls belong in durable workers, not a LiveView process. A browser refresh must not lose the only copy of a job submission or assessment.

## 8. PostgreSQL and tenancy design

Start with one database, one Repo and UUID identifiers. Use timestamps in UTC; store the scheduling zone when wall-clock meaning matters. Add unique/non-null/foreign-key/check constraints for durable invariants and annotate expected constraint errors in changesets. Validate friendly form errors in code while retaining database protection against races.

Migration conventions established in P02 (no application tables exist yet): the migration ledger (`schema_migrations`) starts empty; every future migration runs forward-only in development and is proven by rolling back or re-running against the isolated `joblite_test` database inside an Ecto Sandbox transaction that rolls back on test exit. `config/shared.exs` sets `migration_primary_key` and `migration_foreign_key` to `:binary_id`, so new tables get UUID primary keys and UUID foreign keys by default; `timestamps(type: :utc_datetime)` is the baseline for inserted/updated columns. Add indexes with the migration that introduces the queried column, and prefer composite foreign keys for tenant-consistency invariants (see below). Never migrate a production database from a development session.

Organization-owned rows carry `organization_id`. Candidate profiles are user-owned; an employer sees the version submitted to its job, not unrestricted access to the candidate's evolving profile. Queries and mutations must receive authorized scope, including workers, exports, file access and PubSub-driven refreshes.

For tenant-sensitive parent-child links, enforce consistency with composite foreign keys where appropriate. An application's `organization_id` and `job_id` must reference a job in the same organization; merely filtering list queries does not enforce that invariant. Index foreign-key/tenant filter columns with measured query patterns in mind. Bound pagination and preload intentionally to avoid N+1 queries. Review query plans with representative synthetic data before adding speculative indexes.

Ecto already provides an application connection pool. Budget connections across each deployed instance and worker pool against the database's capacity. Do not add PgBouncer automatically. If later using RLS, use transaction-local tenant settings, separate migration and application roles, and verify policies with the real role and connection pool. A pooled connection must never retain the previous tenant's settings. No RLS policy is implemented in this starter.

Use `Ecto.Multi` or a transaction for coupled business writes and durable task insertion. Do not hold a transaction open during an AI/email HTTP call. Oban, when introduced, uses this same database; workers are modules in core and ship in the monolith release. [Ecto.Multi](https://ecto.hexdocs.pm/Ecto.Multi.html)

For tests, explicitly manage Ecto Sandbox ownership for LiveView and worker processes. Concurrent pure tests and connection-sharing tests have different requirements. Never point tests at production or silently reuse the development database. [Ecto SQL Sandbox](https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html)

## 9. AHIS boundaries and data model

The first complete journey is: owner establishes organization/recruiter access; recruiter publishes a job with explicit criteria; candidate applies; a versioned evidence report is produced; recruiter reviews it and schedules or records a decision; candidate sees permitted status and audit records identify the actor.

| Domain | Owns |
|---|---|
| Accounts | Users, session tokens and identity lifecycle |
| Organizations | Membership, organization roles and scoped authorization |
| Candidates | Candidate profiles, immutable submitted versions and private documents |
| Hiring | Jobs, criteria versions, applications, transitions and recruiter review |
| Intelligence | Assessment runs, evidence references, adapter contracts and evaluation fixtures |
| Scheduling | Interviews, participants, zone-aware display and cancellation |
| Notifications | Stored events and per-channel delivery attempts |
| Audit | Significant actor/resource/action records with restricted metadata |

Implement deterministic criterion evidence before model-generated summaries. Use `supported`, `not_evidenced` and `needs_review`. A missing claim is not proof a person lacks a skill. Version profile inputs, criteria, prompt/schema and assessment outputs. Reject invalid or unsupported model outputs and preserve a manual-review path. Provider failure must not prevent a valid application from being stored.

A provider behaviour has a small semantic contract, such as `assess(input, options) -> {:ok, report} | {:error, reason}`. Add a fake adapter and shared contract cases before a real integration. Keep external credentials in runtime configuration. Minimize personal data sent to a model; never expose privileged tools to untrusted resume instructions. Do not store hidden chain-of-thought as an explanation mechanism. Show source evidence and recorded human corrections instead.

Evaluation cases include missing data, conflicting dates, negated skill claims, hostile instructions, malformed output, stale input versions, timeouts and retry behavior. Report actual case counts and results; finite test success does not establish fairness or accuracy for all applicants.

## 10. Local startup and current verification boundary

The kit's selected target is Elixir **1.20.4** built for OTP 28, Erlang/OTP **28.5**, Phoenix **1.8.x**, LiveView **1.2.x**, Ecto SQL **3.14.x**, and PostgreSQL **18** for the development container. Elixir's published compatibility table supports Elixir 1.20 with OTP 27-29. This is a proposed compatible baseline, not a completed dependency-resolution result. [Elixir compatibility](https://elixir.hexdocs.pm/compatibility-and-deprecations.html)

The Mix files contain dependency ranges and no fabricated lockfiles. P01 must resolve actual versions, review them, format the source, commit both lockfiles and verify the release. The local `postgres:18` tag is a convenient development major tag; pin a reviewed immutable image digest for CI/production. Do not label this kit reproducible until those gates pass.

On the intended Linux host, after installing the pinned toolchain and Docker Compose:

```bash
cd /home/aidomex/Joblite/backend
mix deps.get
mix format
mix test
docker compose up -d postgres
mix ecto.create
mix ecto.migrate
elixir scripts/check_architecture.exs

cd /home/aidomex/Joblite/frontend
mix deps.get
mix format
mix assets.setup
mix assets.build
mix test
mix phx.server
```

In another terminal, inspect `http://localhost:4000/`, `/health/live` and `/health/ready`. Click "Explain the repository boundary" to verify a connected event. `/health/live` means the HTTP process is running; `/health/ready` actually checks the database. The landing page's PostgreSQL label describes architecture and is not a database health claim.

The starter disables Repo startup in test configuration because its initial tests do not use database persistence. P02 must enable a dedicated test Repo, create/migrate `joblite_test`, add DataCase/ConnCase ownership helpers and add actual database tests. Do not claim database isolation has been tested using only the included pure-rule tests.

Local DB credentials in Compose are explicitly development-only and bound to loopback. Never source an untrusted environment file or reuse a production URL.

The local development database is `joblite_dev_db` (user `joblite`, password `joblite_local_only`, `127.0.0.1:5543`); `joblite_test` stays isolated for the test suite. Development secrets are generated with openssl by `scripts/generate_secrets.sh` into gitignored files (`backend/secrets/dev.env`, `frontend/secrets/dev.env`). `config/secrets.exs` loads those files into the Mix configuration for `:dev` only; production and test read real environment variables and the deterministic test values instead. The generator is idempotent: an existing value is kept unless `--force` is passed.

## 11. Integration, CI and two-repository versioning

The two repositories cannot have one atomic Git commit. The implementation atom is a logical unit with paired commits and a tested compatibility record. A change may span both repos; finish validation across the pair before calling the atom complete.

For backend work, test core independently, then check the frontend against the proposed backend SHA. For frontend work, test against the documented compatible backend SHA. A CI workspace must check both out as sibling `backend/` and `frontend/` paths; checking out only frontend cannot satisfy its path dependency.

Required checks: formatting, compile warnings as errors, meaningful ExUnit tests, connected LiveView tests, architecture smoke checks, asset build, migration tests on an isolated PostgreSQL instance, and release assembly/boot before a release. Add Credo, Sobelow and dependency checks in P01 after reviewing the actual versions and findings. Add a small browser test for actual asset/WebSocket behavior; LiveViewTest alone does not run browser JavaScript. [LiveView testing](https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html)

A release manifest records API-independent core/web commits, both lockfile hashes, runtime versions, migration version, asset digest, artifact digest and validation evidence. Store it in `frontend/releases/`. A frontend lockfile does not capture the commit of `../backend`, so the two SHAs are required. Keep API/context contract changes backward-compatible until the paired web change is ready; use expand/contract database changes when deploying old and new code concurrently.

No GitHub repositories, CI credentials or remotes are assumed or created. Configure those after repository ownership is known. CI must not execute untrusted code with deployment credentials.

## 12. Release configuration and operations

Build from the frontend directory with both sibling sources present. Compile assets, assemble one release and run migrations explicitly through `JobliteWeb.Release.migrate/0`. Database migrations belong to core even though the release helper is called from the product entry point. [Phoenix releases](https://phoenix.hexdocs.pm/releases.html)

Required production environment in this starter: `DATABASE_URL`, `DATABASE_CA_CERT`, `DATABASE_SSL_SERVER_NAME`, `SECRET_KEY_BASE`, `PHX_HOST`; optional `POOL_SIZE` and `PORT`. The CA path must exist in the deployed runtime. Verify TLS hostname/certificate behavior against the actual provider before production. Generate the secret with `mix phx.gen.secret`; never copy the development secret. Place the HTTP port behind a trusted TLS proxy and prevent direct public bypass of proxy assumptions.

Two images exist, and the difference is ownership, not preference. The repository-root `Dockerfile` builds the core release (`:joblite_core`) from this repository alone: no endpoint, no router, no port; it boots the Repo and the PubSub and answers readiness through the core's own bounded probe. The product image (`deploy/Dockerfile`, build context = the workspace parent) assembles the `joblite` release with the sibling frontend and serves HTTP. A core image therefore requires `DATABASE_URL` (plus the TLS policy variables) and nothing else: `PHX_HOST`, `PORT` and `SECRET_KEY_BASE` belong to the browser-facing release. Migrations stay explicit in both images.

P01/P11 must prove a Linux artifact can start from a temporary directory with no source checkout, and that config contains no development credentials, original source paths or compiled secrets. Do not import sibling runtime config files from `runtime.exs`; those source paths will not exist inside the release.

Use request IDs and structured event/job IDs. Log errors at their boundary without dumping candidate text or tokens. Track database readiness, job lag/failures and provider errors separately. Restore synthetic backups in isolation. Roll back code only across compatible schemas; destructive schema reversal requires a tested recovery plan, not an automatic down migration.

## 13. Debugging playbook

| Symptom | Inspect first | Explain the boundary |
|---|---|---|
| Mix fails before compiling | `elixir --version`, `erl`, PATH, runtime installation | A runtime/toolchain issue precedes application source. |
| Frontend cannot find core | Sibling checkout path and app name in Mix | Source dependency resolution, not an HTTP failure. |
| Missing Repo configuration | Frontend's import of core shared config; active environment | Dependency configs are not automatically adopted. |
| Readiness 503 | Repo startup, URL, DB reachability, TLS and pool | Liveness is separate from dependency readiness. |
| HTML renders but events fail | Asset build, JS errors, CSRF meta, `/live`, proxy upgrades | Disconnected rendering and connected events are different paths. |
| Tenant record missing/forbidden | Server scope, membership and context query | Do not disable authorization to make the screen work. |
| LiveView test ownership error | Sandbox owner lifecycle and allowances/shared mode | The LiveView is a separate process from the test. |
| Duplicate task/notification | Business idempotency key and per-channel result | Retryability is not exactly-once delivery. |
| AI result stale or unsupported | Input/version hashes, schema validation, source evidence | Never repair uncertainty by inventing successful output. |
| Release works only beside source | Runtime imports, priv contents and build manifest | Deployment must contain all runtime resources. |

Reproduce one failing behavior, identify the owning module, write the smallest useful regression case, fix the cause, and re-run the relevant gate. Do not add broad rescue clauses, global flags or copied code to suppress an unexplained failure.

## 14. Documentation and comprehension standard

Every atom leaves: behavior and scope, changed files and their responsibilities, public contracts, relevant tests/results, migration impact, error paths and a source walkthrough. Use the templates in `TEMPLATES.md`. Update `STATUS.md` with evidence, not optimistic checkmarks.

Before completing a feature, the developer must be able to describe its user value; trace a request/event through each relevant file; identify the authorization and transaction boundaries; explain a failure and recovery; and make a small change without relying on a generated narrative. This is a portfolio acceptance criterion, not a demand for excessive comments in code.

Keep onboarding, architecture, domain rules, ADRs, runbooks and actual release evidence near source. The old assessment's lessons about ambiguous deploy paths, duplicated admin, secrets and false completion claims remain applicable. Preserve the legacy workspace as a private reference; do not copy it wholesale into the new repositories.
