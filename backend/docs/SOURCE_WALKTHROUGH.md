# Walkthrough of the included source

This guide describes authored code. It does not replace the P01 compilation and runtime gates.

## 1. How one application starts from two repositories

Open `frontend/mix.exs`. The `:joblite_core` path dependency points to `../backend`.
The web application does not call an API or copy domain code. Mix/OTP start runtime
dependencies before `JobliteWeb.Application`; core's supervisor starts PubSub and,
outside the initial test environment, the Repo. Web starts the Endpoint.

`backend/config/shared.exs` declares the core Repo settings. `frontend/config/config.exs`
imports them explicitly. The core dependency's own config is not automatically applied.
Production secrets and Repo TLS options are read by frontend's `runtime.exs` inside the
assembled product. Runtime startup does not import an external backend config file.

## 2. From a browser page to a core function

1. `frontend/lib/joblite_web/endpoint.ex` handles transport, request IDs, parsers and session.
2. `router.ex` applies the browser pipeline, CSRF protections and root layout to `/`.
3. `live/home_live.ex:mount/3` calls `Joblite.Health.architecture/0` directly.
4. `backend/lib/joblite/health.ex` returns descriptive architecture data.
5. `live/home_live/render.html.heex` displays those values as server-rendered markup.
6. `assets/js/app.js` connects the Phoenix LiveView client using the CSRF token.
7. Clicking the details button invokes `handle_event/3`, which changes display state only.

The HEEx template is separate because markup and event coordination are different
responsibilities. There is no extra service object between the LiveView and a trivial
public core function. Adding one would not improve this slice.

The included LiveView test checks disconnected markup, a connected view and an event.
It is authored but not run. It also does not run browser JavaScript; a browser smoke
check is still required to validate asset delivery and the actual WebSocket connection.

## 3. Liveness versus readiness

`controllers/health_controller.ex` maps HTTP responses. `/health/live` reports only
that the HTTP process can respond. `/health/ready` delegates to core readiness.
`Joblite.Health.readiness/0` checks that Repo is started and performs a bounded `SELECT 1`.
Expected connection failures become a not-ready result, mapped to HTTP 503.

The frontend never queries Repo. The landing page's "PostgreSQL" label describes the
chosen architecture; it is not a pretend database measurement. Do not expand this health
module into a command center or a collection of unrelated domain utilities.

## 4. A small pure business rule

`backend/lib/joblite/hiring/stage.ex` owns a stage-transition graph. It accepts data and
returns tagged results without reading a database, authorizing a user or sending messages.
The tests cover a forbidden jump from submitted to hired, terminal-state reopening and
unknown client values. `cast/1` maps only known strings and never creates arbitrary atoms.

This is one small teaching slice, not an implemented ATS. A future authorized context
must load the application, enforce tenant and actor rules, apply the pure transition,
and persist the result/audit event transactionally with concurrency protection.
Do not call the stage module directly from UI code as a substitute for that context.

## 5. The release boundary

The release named `joblite` is assembled in frontend and contains both OTP applications.
`frontend/lib/joblite_web/release.ex` locates core's configured Repo for explicit migrations.
This release helper is composition infrastructure; UI callbacks still cannot bypass contexts.

P11 must prove the artifact starts without either source checkout. Successful compilation
alone does not establish this property. Production also requires real runtime credentials,
database CA/hostname verification, proxy/origin validation and a tested migration path.

## 6. Comprehension exercise

Explain why the two repos need paired source revisions; why frontend's lockfile controls
integrated resolution; why core config is imported at build time but not from an external
path at release startup; why a stage rule is pure; and why a test-mode Repo is initially
disabled. Then add a small display-only change and trace its event without moving domain
logic into the LiveView. Record the result using the explanation checkpoint template.
