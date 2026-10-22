# Atomic implementation plan

Execute in dependency order. A checked box needs source and verification evidence.
The supplied foundation is authored but uncompiled; P01 is still open.
Use the atom template in `TEMPLATES.md`. Do not build future features to bypass a blocked prerequisite.

## Working unit and gate

An atom delivers one observable behavior or one verifiable foundation change, normally in a handful of cohesive files. A migration, context operation, UI event and tests may form one atom when they jointly deliver that behavior. Do not split a working invariant across unrelated unfinished commits just to reduce the diff size.

Before coding: name the responsibility, inputs/results, actor/scope, affected files and negative case. During coding: implement the smallest correct path and its meaningful checks. After coding: review the diff, run checks, explain the trace, record evidence and the next ready atom. An automatic phase gate checks readiness; it is not an extra permission request. Pause for user input only when access, a material product choice or an irreversible action genuinely requires it.

Across two Git repos, an atomic implementation means a tested pair of changes; it cannot mean one Git transaction. Record both commits after review. Do not push, publish or deploy merely because local checks pass.

## P00 - Architecture and source workspace

**Layer:** source ownership and architectural constraints.  
**Depends on:** the user's accepted Phoenix/LiveView/PostgreSQL direction.

| Atom | Deliverable | Acceptance and explanation |
|---|---|---|
| P00.01 | Record architecture decision: two sibling repos, one release | Identify core/web ownership and explain why no internal HTTP API is needed. |
| P00.02 | Initialize backend and frontend without touching legacy source | Verify two separate Git roots and no parent repo created by this process; preserve existing files. |
| P00.03 | Add handbook, standards, templates and implementation prompt | Paths, app names and dependency direction agree across docs. |
| P00.04 | Add the minimal authored foundation and status ledger | Every included file has an identified responsibility; unexecuted checks remain explicitly open. |

**Exit:** source installed on the intended host, ownership agreed and repository state recorded. This kit prepares those files; installation at `/home/aidomex/Joblite` is not claimed.

## P01 - Toolchain, dependency wiring and first LiveView

**Layer:** executable application skeleton.  
**Depends on:** P00.

| Atom | Deliverable | Acceptance and explanation |
|---|---|---|
| P01.01 | Verify the actual host, paths and pinned runtime | `elixir --version`/Mix execute; both repos use one documented Elixir/OTP pair. Diagnose runtime failure before application changes. |
| P01.02 | Resolve core dependencies, format and run pure-rule tests | Commit a real backend lockfile after review; stage-rule tests pass. Explain immutable rules versus effects. |
| P01.03 | Resolve the assembled frontend dependency graph | Frontend lockfile resolves the compatible core pair; no circular deps or source copied into a second domain implementation. |
| P01.04 | Build assets and exercise connected HomeLive | UI renders core data; a click traverses the LiveView event path. Browser JS/WebSocket smoke confirms more than static rendering. |
| P01.05 | Add source quality and independent/integration checks | Both repos format/compile; smoke boundaries pass; add/review Credo and Sobelow. Explain what each check does not prove. |
| P01.06 | Assemble the first `joblite` release and inspect contents | One artifact contains core/web and compiled assets; runtime config has no sibling-source import. Record that production boot remains a P11 gate. |

**Exit:** genuine compile/test/build evidence and dependency locks exist; code changes needed to make the authored starter compile are reviewed and documented. No authenticated hiring feature is implied.

## P02 - PostgreSQL lifecycle and test infrastructure

**Layer:** persistence foundation.  
**Depends on:** P01.

| Atom | Deliverable | Acceptance and explanation |
|---|---|---|
| P02.01 | Create/migrate isolated development and test databases | Verify database names and the empty/current migration ledger; never use production. Explain Repo ownership/configuration. |
| P02.02 | Enable test Repo and add Sandbox helpers | Tests prove connections use `joblite_test`; owner lifecycle supports future LiveView tests without leaking transactions. |
| P02.03 | Exercise readiness and database failure behavior | Ready endpoint returns success with DB available and 503 when unavailable; liveness remains independent. |
| P02.04 | Establish migration/index/constraint conventions | Document UUIDs, UTC timestamps, foreign keys and test rollback strategy. No speculative application tables. |

**Exit:** actual database tests run; test helpers are not merely copied from generated examples. Database transport, configuration and migrations can be explained separately.

## P03 - Accounts, sessions and organizations

**Layer:** identity, ownership and authorization.  
**Depends on:** P02.

| Atom | Deliverable | Acceptance and explanation |
|---|---|---|
| P03.01 | Accounts schema, identity lookup and session token lifecycle | Unique identity and token revocation/expiry tests pass. Adapt generator output to core/web separation before accepting it. |
| P03.02 | Login/logout and LiveView authentication integration | Both HTTP and connected mount validate session; public/protected routes behave intentionally. |
| P03.03 | Organizations, memberships and scoped roles | Two seeded organizations; candidate global identity and organization-specific role are distinct. |
| P03.04 | Scope/policies and authorization regression cases | Cross-tenant read/write/guessed-ID tests fail safely; revoked membership cannot keep acting through a mounted LiveView. |

**Exit:** a browser route is not the only permission boundary. Public context operations reauthorize sensitive actions. No hiring data is added until this foundation is credible.

## P04 - Accessible UI shell and component vocabulary

**Layer:** presentation foundation.  
**Depends on:** P03.

| Atom | Deliverable | Acceptance and explanation |
|---|---|---|
| P04.01 | Candidate/recruiter navigation and signed-in shell | Role-appropriate navigation, server-authorized page access and visible session-expiry behavior. |
| P04.02 | Small form, button, status and empty/error components | Explicit attrs/slots; keyboard/focus/error labeling checks; no catch-all core-components file. |
| P04.03 | Bounded page-state patterns and reconnect behavior | Loading, empty, forbidden, failed and stale states differ; errors are not rendered as fake zero counts. |

**Exit:** subsequent features use a small consistent UI vocabulary. Stateless markup stays in function components; LiveComponents have a demonstrated need for local state.

## P05 - Jobs and versioned criteria

**Layer:** first employer feature.  
**Depends on:** P03-P04.

| Atom | Deliverable | Acceptance and explanation |
|---|---|---|
| P05.01 | Job schema and draft context operation | Organization ownership and required fields enforced by policy/changeset/database. |
| P05.02 | Job creation/edit LiveView | Valid and invalid form submissions tested through the context boundary. |
| P05.03 | Publication/closure and public list/detail | Only published permitted fields appear publicly; closed jobs cannot accept new applications. |
| P05.04 | Versioned job criteria | Criteria changes create versions; previous assessments can retain their original criteria reference. |

**Exit:** an authorized recruiter publishes a job and an anonymous visitor sees only allowed content. Explain which rule belongs in a pure module, changeset, policy and constraint.

## P06 - Candidate profile and application submission

**Layer:** candidate-to-employer workflow.  
**Depends on:** P05.

| Atom | Deliverable | Acceptance and explanation |
|---|---|---|
| P06.01 | Candidate-owned structured profile and versioning | Another candidate cannot mutate/read private profile fields; submitted versions are immutable. |
| P06.02 | Application transaction and uniqueness | Concurrent duplicate submissions produce one application; organization/job consistency is enforced. |
| P06.03 | Apply LiveView and candidate application list | Candidate ID derives from server session; context errors map to useful UI states. |
| P06.04 | Employer access to submitted snapshot | Employer sees only applications for its organization and only the permitted submitted version. |

**Exit:** the complete apply journey works without any AI or document parser. Add uploads only as a separate reviewed atom with storage/access/type/size controls.

## P07 - Recruiter review, stage transitions and audit

**Layer:** controlled hiring workflow.  
**Depends on:** P06.

| Atom | Deliverable | Acceptance and explanation |
|---|---|---|
| P07.01 | Bounded recruiter application queries | Tenant filter, pagination, search and preload behavior have tests. |
| P07.02 | Authorized transition use case | Use the stage rule, expected version/lock and one transaction for state/audit changes. Invalid and stale transitions fail. |
| P07.03 | Recruiter review LiveView | Internal notes and candidate-visible state are distinct; no SQL in events. |
| P07.04 | Candidate status and audit timeline | Actor/reason/time are traceable; candidate cannot access internal recruiter notes. |

**Exit:** a recruiter can review and change a stage safely, while another organization and an outdated screen cannot overwrite it.

## P08 - Durable deterministic AHIS assessments

**Layer:** background automation and explainable rules.  
**Depends on:** P07.

| Atom | Deliverable | Acceptance and explanation |
|---|---|---|
| P08.01 | Assessment/run/evidence schema and pure criterion rules | Supported/missing/needs-review results identify versioned input evidence; missing data is not a negative ability claim. |
| P08.02 | Oban queue and atomic task insertion | Submission/assessment requests create durable tasks; insertion failure cannot disappear into success. |
| P08.03 | Idempotent worker and stale-result protection | Retry/restart does not duplicate results; changed inputs supersede an old run. |
| P08.04 | Assessment review LiveView and safe PubSub refresh | Connected authorized users see task status and evidence; reconnect reconciles from storage. |

**Exit:** queued/running/ready/failed states are demonstrated with failure tests. The ATS remains usable if assessment work fails.

## P09 - One grounded AI integration

**Layer:** controlled external variation.  
**Depends on:** P08.

| Atom | Deliverable | Acceptance and explanation |
|---|---|---|
| P09.01 | Small provider behaviour, fake adapter and shared contracts | Success, timeout, invalid response and error semantics are explicit; no provider can alter hiring state. |
| P09.02 | Real adapter and output validation | Runtime credentials, deadlines, bounded retry/usage and schema/source validation work. No network call inside DB transactions or LiveView callbacks. |
| P09.03 | Versioned evaluation set and release report | Include hostile text, negation, missing data, malformed/stale outputs and outages; record actual case counts/results. |
| P09.04 | Human correction and review record | Recruiter can inspect source evidence and record a reasoned correction; unsupported output is not presented as fact. |

**Exit:** model-assisted output is useful, inspectable and honestly limited. No automatic rejection/offer/hire, inferred personality analysis or unsupported accuracy claim.

## P10 - Interviews and reliable notifications

**Layer:** workflow coordination and side effects.  
**Depends on:** P07; use P08's task foundation.

| Atom | Deliverable | Acceptance and explanation |
|---|---|---|
| P10.01 | Interview scheduling/cancellation and zone-aware UI | Store UTC plus meaningful scheduling zone; invalid participants and stale reminders are rejected. |
| P10.02 | Stored in-app notifications and delivery records | User-scoped reads; one business event has explicit per-channel outcome and idempotency key. |
| P10.03 | Optional approved email through one adapter | Failed/ambiguous sends are observable; retry does not blindly duplicate known successes. |
| P10.04 | Reconnect/deduplication and cancellation regression | A notification arriving twice is presented once; cancelled interviews suppress obsolete work. |

**Exit:** scheduling and in-app status work with external delivery disabled. Push/TWA/live video remain outside initial scope.

## P11 - Deployable portfolio release

**Layer:** operational proof and explanation.  
**Depends on:** P01-P10 gates for included features.

| Atom | Deliverable | Acceptance and explanation |
|---|---|---|
| P11.01 | CI for a tested source pair and immutable build record | Both repos checked out as siblings at explicit SHAs; locks/runtime/artifact/migration details recorded. |
| P11.02 | One Linux release deployed to staging | Boots from an artifact with no source checkout; TLS/proxy/origin/session behavior and database TLS verified. |
| P11.03 | Migration, backup/restore and compatible rollback exercise | Restore synthetic data in isolation; distinguish code rollback from schema recovery. |
| P11.04 | Small browser/E2E and operational smoke suite | Demonstrate candidate apply, recruiter review, assessment and interview plus second-tenant denial and outage recovery. |
| P11.05 | Portfolio README, case study and source walkthrough | Reviewer can reproduce setup; owner can explain implementation, tests, tradeoffs and unfinished work. |

**Exit:** release proof, actual evaluation results and source understanding exist. Public publication/deployment still follows the user's authorization and actual target access.

## Scope after P11

Only add payments, social feeds, streaming, Android packaging, multi-region infrastructure or multiple AI providers after a separate product decision. Do not equate modularity with mandatory microservices. The default remains this monolith.
