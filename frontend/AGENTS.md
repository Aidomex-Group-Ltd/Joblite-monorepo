# Joblite LiveView implementation instructions

Read ../backend/docs/STATUS.md, DEVELOPMENT_HANDBOOK.md, PHASES.md and TEMPLATES.md.
This is `:joblite_web`, namespace JobliteWeb, depending on sibling :joblite_core.

- Keep one release and one Endpoint. No React, SPA, second database or internal HTTP client.
- Call public core contexts; UI modules do not access Repo or import Ecto.Query.
- Keep LiveView callbacks thin. Do not put domain transactions or provider HTTP calls in them.
- Validate HTTP/connected identity and reauthorize sensitive events against current scope.
- Reusable stateless markup uses function components; stateful components need a real reason.
- Keep templates/components and modules small by responsibility, following core handbook limits.
- Use clear loading/empty/failed/forbidden states; never invent metrics or hide errors as empty data.
- Frontend owns release/runtime composition; do not import sibling source config at release boot.
- Run relevant LiveView, browser/asset and core-integration checks; report unexecuted checks honestly.
- Update canonical docs in backend rather than duplicating architectural policy.
