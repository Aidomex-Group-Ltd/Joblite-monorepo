# ADR 0001: Two sibling repositories assembled into one release

Status: accepted, 20 October 2026.

## Problem and constraints

Joblite AHIS must be understandable, explainable and debuggable from source. The
product needs a web UI plus domain logic, must run on PostgreSQL, and must deploy as
one artifact. An earlier proposal used a Phoenix JSON API plus a separately deployed
React client, which introduced an internal HTTP boundary, a second build/deployment
surface and duplicated rules.

## Options considered

1. Two repositories, two OTP applications, one BEAM and one release, with the web app
   depending on core through a Mix sibling path dependency.
2. One repository with both applications in a single Git root.
3. Two independently deployed services with an internal HTTP API between them.

## Chosen approach and reason

Option 1: `backend` (`:joblite_core`, `Joblite.*`) and `frontend` (`:joblite_web`,
`JobliteWeb.*`) are separate Git repositories at the requested paths, with frontend
declaring `{:joblite_core, path: "../backend"}`. Public context functions are ordinary
Elixir calls in one BEAM, so no internal HTTP API exists: there is no network hop,
serialization, version skew or second deployment unit to manage. One release
(`MIX_ENV=prod mix release joblite`, assembled in frontend) contains core, web and
dependencies. Option 2 violates the required two-path workspace layout; option 3
creates exactly the boundary this architecture rejects.

## Dependency, data and security impact

Dependency direction is one-way: `JobliteWeb` -> public `Joblite.*` contexts ->
internal policies/rules/queries -> `Joblite.Repo`. Core never depends on LiveView,
`Plug.Conn` or `JobliteWeb`; UI modules never query Repo or import `Ecto.Query`.
Only backend touches PostgreSQL through the single `Joblite.Repo`. Authorization
happens in core so every entry point (LiveView, worker, release task) applies the
same rules. Mix ignores a dependency's lockfile, so the frontend lockfile governs
integrated resolution and the backend lockfile serves standalone checks; the two
repositories are paired by explicitly recorded compatible commits.

## Tradeoffs and rejected complexity

Rejected: microservice separation, GraphQL/REST internal API, duplicated browser-side
domain rules, a shared third repository at the workspace parent, and a generic
service layer between LiveView and trivial context functions. Cost of this choice:
the two repos cannot share one atomic Git commit, so compatibility must be recorded
as a pair of SHAs.

## Verification

`scripts/check_architecture.exs` smoke-checks the dependency direction and file
sizes; P01 compilation, tests and release assembly provide runtime evidence. This
ADR is verified by repository state (two Git roots, no parent repository) plus those
checks as they complete.

## When to revisit

Revisit only after a separate product decision that requires independent deployment
of the web tier or a second data store. Modularity alone is not a reason to split
the monolith.
