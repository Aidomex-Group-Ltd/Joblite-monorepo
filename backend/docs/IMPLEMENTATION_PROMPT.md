# Reusable implementation prompt

Paste the following into the implementation session on the intended Linux host.
This prompt supersedes React/API architecture instructions in the previous report.

---

You are rebuilding Joblite AHIS so that I can understand, explain and debug its source.

Use these exact sibling repositories:

- `/home/aidomex/Joblite/backend`: Git repository, OTP app `:joblite_core`, modules `Joblite.*`.
- `/home/aidomex/Joblite/frontend`: Git repository, OTP app `:joblite_web`, modules `JobliteWeb.*`.

Build one modular monolith using Elixir, Phoenix, LiveView, HEEx and PostgreSQL.
The frontend depends on the backend through a Mix path dependency. It calls public
contexts directly in the same BEAM. Assemble one `joblite` release from frontend.
There is one Ecto Repo in backend. No React, SPA, internal HTTP API, second database,
independently deployed frontend/backend, or third workspace repository.

Read applicable AGENTS.md files, then backend/docs/STATUS.md,
DEVELOPMENT_HANDBOOK.md, PHASES.md and TEMPLATES.md. Inspect actual files before coding.
Do not assume the authored starter compiles or that old Joblite features exist here.
Keep the original legacy workspace unchanged.

For this invocation, implement the next ready atomic item from PHASES.md. If the
user names a phase/atom, respect that scope and verify its prerequisites first.
On a fresh installation, start with P00 installation verification, then P01.01.
Do not mark a prerequisite complete from a completion marker, source count or a
test that was never run. Report the current scope and acceptance case before edits.

Apply SRP, SOLID, all GRASP responsibility patterns, KISS, DRY, YAGNI, separation of
concerns, least privilege and composition idiomatically for a functional language.
Use immutable data, pure rules and cohesive modules. Behaviours belong at actual
provider boundaries; avoid class hierarchies, generic repository wrappers, catch-all
utilities, and a process or interface for every function. A GenServer needs a real
lifecycle/concurrency responsibility. A small file alone does not prove SRP.

Keep authored modules and templates usually 50-200 lines. Review above 250 lines;
the project smoke gate rejects lib source/templates above 400. Prefer short readable
functions, clear names, public docs/specs and explicit tagged errors. Extract by
responsibility rather than line count. Never compress code to evade a limit.

Respect dependency direction: JobliteWeb -> public Joblite contexts -> internal
policies/rules/queries/use cases -> Repo/adapters. Core must not depend on LiveView,
Plug.Conn or JobliteWeb. UI modules must not query Repo or import Ecto.Query.
Phoenix.PubSub is allowed in core as an infrastructure component. Frontend release
configuration may configure core and invoke core migrations; this is not permission
for presentation code to access persistence.

For each atom:

1. State its user-visible behavior or verifiable infrastructure result, affected
   layer, prerequisites, public contract, actor/scope and important failure case.
2. Identify a small set of files and each file's responsibility. Do not create
   placeholders for future phases.
3. Implement the minimal rule/schema/constraint/policy/context path. Use one
   transaction for coupled durable changes and task insertion where required.
4. Add the LiveView/HEEx slice only after the context behavior is correct. Keep
   callbacks thin; validate HTTP and connected-session identity, and reauthorize
   sensitive events because membership can change while the page is mounted.
5. Add meaningful tests for invariants, tenant denial, concurrency or failure
   behavior relevant to the atom. Use proper Sandbox process ownership when needed.
6. Run the required checks on the correct environments/databases. Include source
   formatting, compilation warnings, relevant tests, architecture smoke checks and
   asset/connected-browser verification when affected. Do not claim checks passed
   when tools or access prevented execution.
7. Review the diff and explain the source flow: entry point -> context -> rule/policy
   -> query/transaction -> result -> UI. Explain why files were split, what error is
   returned, and how a developer would diagnose a failure.
8. Update STATUS.md and the atom evidence record with actual results, compatible
   repo state and the next ready atom. A change across two repos is a tested pair,
   not one atomic Git commit. Do not invent SHAs or lockfiles.

The initial hiring journey is publish job -> apply with versioned candidate inputs
-> criterion evidence report -> recruiter review -> interview/recorded decision ->
candidate-visible status. Build it without AI first. Add Oban and one AI provider only
in their planned phases. AI work must be durable, versioned, schema/evidence-validated
and recoverable. Keep hiring decisions and outgoing recruitment communications under
human approval. Use synthetic data; protect candidate data and runtime credentials.

Two-repo build rules: check out both as siblings at explicit compatible commits;
frontend's lockfile controls integrated resolution; backend's lock serves standalone
checks. Dependency config is not automatically loaded. Runtime config must be inside
the assembled release and must not import sibling source files at boot. Production
release proof requires starting the artifact without a source checkout.

When blocked, reproduce and state the exact blocker, preserve work and complete any
independent documentation/checks within the current atom. Do not bypass a gate by
removing tests, suppressing errors, weakening authorization or silently changing the
stack. Ask only for information/access that is actually missing. Ordinary reversible
implementation steps and automatic validation gates need no repeated approval.

End this scoped atom with: outcome, changed files and responsibilities, relevant
validation with pass/fail/not-run status, a concise code walkthrough, remaining risks,
and the next atom. Do not implement a future feature phase merely to make progress
look larger. The completion criterion is working, verified, explainable behavior.

---

Suggested initial follow-up after installation: "Implement P01.01 only: verify the
Linux workspace and toolchain, resolve any environment-specific blocker safely,
record evidence, and explain the two-OTP-app/one-release boundary."
