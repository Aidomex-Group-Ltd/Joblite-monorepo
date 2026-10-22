# Implementation and handoff templates

## Atomic change record

```text
Atom: Pxx.yy
Status: planned | in_progress | verified | blocked
Behavior/result:
Prerequisites and actual evidence:
Actor and authorized scope:
Public operation and tagged results:
Invariant and failure case:
Files and one-sentence responsibilities:
Migration/data impact:
Tests/checks: command, environment, pass/fail/not_run, useful result
Source walkthrough:
Debugging entry point and request/job identifier:
Core/web compatible commits: actual SHAs, or explicitly uncommitted
Remaining risk:
Next ready atom:
```

## Architecture decision record

```text
ADR number and title:
Status and date:
Problem and constraints:
Options considered:
Chosen approach and reason:
Dependency/data/security impact:
Tradeoffs and rejected complexity:
Verification:
When to revisit:
```

## Feature source map

```text
User action:
LiveView route/module/template:
Authenticated scope construction:
Context public function:
Policy and pure rule:
Queries and schema:
Transaction and database constraints:
Background task and idempotency:
Returned errors and UI mapping:
Meaningful tests:
One failure/recovery walkthrough:
```

## Release record

```text
Release ID:
Core commit:
Web commit:
Backend lock SHA-256:
Frontend lock SHA-256:
Elixir/OTP and database versions:
Schema/migration version:
Asset/artifact digests:
Configuration revision (no secret values):
Actual validation evidence:
Known limitations:
Compatible rollback target and schema implications:
Backup/restore proof:
```

## Explanation checkpoint

The developer explains: what the feature does; why each module exists; where access
is checked; what is atomic; what can fail; how a retry behaves; which tests prove
the important property; and how to make a small change. If explanation requires
inventing behavior absent from the source, the feature is not ready for a portfolio claim.
