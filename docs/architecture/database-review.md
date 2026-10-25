# Database architecture review

This review reconciles the PostgreSQL model with the product boundaries in
`tasks.md` section IV. The schema is intentionally broader than the first
release, but it must remain operable by a small self-hosting team.

## Executive assessment

The relational model is a good fit for GoShipKit: PostgreSQL handles projects,
workflows, traceability, stakeholder projections, audit history, and a modest
background-job queue without adding another datastore. The main risk was not a
missing database technology; it was inconsistent project ownership across
generic or indirect references.

Migration `000002_database_invariants.up.sql` closes the highest-priority gaps:

- requirements become first-class traceability records;
- direct, join-table, work-item, and generic-link references cannot cross
  project boundaries;
- explicit visibility grants must point at an existing entity in that project;
- audit records are immutable except when a referenced principal is deleted;
- project and milestone progress use one documented task-counting formula;
- workers claim jobs with row locking, and operators can recover expired jobs;
- a lightweight migration ledger records the bootstrap state.

## What belongs in PostgreSQL

- Foreign keys, uniqueness, value checks, and project-boundary integrity.
- Stable derived read models such as task-count progress views.
- Atomic worker coordination with `FOR UPDATE SKIP LOCKED`.
- Append-only audit protection and encrypted-or-hashed secret storage.

## What stays in Go

- Role/capability decisions and field-level stakeholder projections.
- Workflow transition policy, notifications, and approval rules.
- Integration reconciliation, retry scheduling, and encryption key handling.
- User-facing validation and error translation.

Database triggers are a final integrity boundary, not a replacement for the
authorization policy in `server/internal/auth` and project-scoped queries.

## Deliberately deferred

- Row-level security (RLS) is deferred until the API has a reviewed strategy
  for transaction-scoped identity with pooled connections. It is a release
  gate before offering a shared multi-tenant hosted service, not for the first
  single-organization self-hosted release.
- Materialized progress views are unnecessary at the expected team size.
  Measure normal views first; add caching only from observed query plans.
- Partitioning audit/activity tables is premature. Reassess when retention or
  table size makes vacuum, backup, or query latency measurably problematic.
- A graph database is unnecessary. `entity_links` plus indexed relational
  joins covers the traceability depth in the product scope.
- Business-heavy stored procedures are avoided because they split domain logic
  between Go and SQL and make application testing and upgrades harder.

## Release gates

Before calling the database production-ready:

1. Run every migration against an empty database and a copy of the previous
   release, then exercise rollback by restoring the pre-migration backup.
2. Add integration tests that attempt cross-project references and unauthorized
   stakeholder reads, not only successful paths.
3. Test backup restoration on a separate database at least once per release.
4. Capture `EXPLAIN (ANALYZE, BUFFERS)` for project board, stakeholder portal,
   activity feed, and progress queries with representative data.
5. Use separate migrator and runtime database roles before public deployment;
   the runtime role should not own the schema or bypass future RLS policies.
