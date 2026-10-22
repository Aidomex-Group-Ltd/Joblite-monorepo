# Frontend repository guide

This is the Phoenix/LiveView application `:joblite_web`, not a React client.
It depends on `../backend` (`:joblite_core`) and assembles the single `joblite` release.

Canonical documentation lives in `../backend/docs/DEVELOPMENT_HANDBOOK.md`.
Read `../backend/docs/PHASES.md` and `../backend/docs/STATUS.md` before implementing features.

Allowed here: routes, HTTP session integration, on_mount hooks, LiveViews, HEEx,
function components, browser hooks, CSS, UI tests and release assembly/configuration.
Call public `Joblite.*` context functions. Do not query `Joblite.Repo`, import
`Ecto.Query`, implement hiring rules in events, or call core over HTTP.

Build/config files may configure the core Repo and run the core migration release helper.
That composition-root role does not permit UI modules to access persistence.

The initial HomeLive uses core metadata and handles a connected event. It is not
an ATS, an authentication implementation or evidence that PostgreSQL was tested.
The local runtime prevented compilation in the authoring session. P01 remains open.

## Verified in the Linux implementation session (P01.04)

`scripts/browser_smoke.js` drives a headless Chromium against `mix phx.server` on
`http://localhost:4000` and asserts asset delivery, a joined LiveView WebSocket,
a working `phx-click` event and liveness. ExUnit LiveView tests do not execute
browser JavaScript, so this smoke check complements them. Readiness legitimately
returns 503 until the P02 database exists. The dev `check_origin: true` setting
allows the configured `url` host `localhost` only.
