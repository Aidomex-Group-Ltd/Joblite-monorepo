# Joblite core implementation instructions

Read docs/STATUS.md, docs/DEVELOPMENT_HANDBOOK.md, docs/PHASES.md and docs/TEMPLATES.md.
Implement the requested atom; verify prerequisites and report real check results.

- This repo is `:joblite_core`, namespace Joblite. It owns domain rules, policies,
  schemas, queries, Repo, migrations and workers.
- It is part of one Phoenix/LiveView monolith with sibling `../frontend`; no core HTTP API.
- Do not depend on JobliteWeb, LiveView or Plug.Conn. Phoenix.PubSub is allowed.
- Use public contexts as the domain boundary. Keep policy/rules/persistence/effects distinct.
- Use idiomatic functional composition. Apply SOLID/GRASP intent without artificial OOP layers.
- Keep files cohesive: target 50-200 lines; review above 250; lib/template smoke limit 400.
- Never sacrifice clarity or security merely to meet a size rule.
- Authorize server-derived scope, preserve tenant invariants and use database constraints.
- Do not blanket-rescue to success or introduce arbitrary atom conversion from client values.
- Keep secrets and real candidate data out of source, fixtures, logs and documentation.
- Run relevant checks and record pass/fail/not-run honestly. Do not invent lockfiles or SHAs.
- Preserve legacy source. Do not publish, deploy or create remotes without authorized scope.
- Explain each changed file's responsibility and the source trace before completing the atom.
