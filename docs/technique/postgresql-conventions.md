# PostgreSQL conventions

- Store identifiers as UUID and timestamps as UTC `timestamptz`.
- Use foreign keys for ownership and triggers only for invariants that span several tables and cannot be expressed as a normal constraint.
- Keep authorization policy in Go; keep tenant/project referential integrity in PostgreSQL.
- Use `text` plus checks for evolving workflow values instead of PostgreSQL enums that require disruptive migrations.
- Store verifiable bearer tokens as hashes. Encrypt provider credentials in the application before persistence.
- Add indexes for foreign-key join paths and measured query patterns, not speculatively for every column.
- Use keyset pagination for growing activity, audit, notification, and integration-event feeds.
- Treat audit events as append-only. Do not automatically audit every row mutation without actor/request context.
- Prefer normal views for small-team derived metrics. Introduce materialized views only after query plans show a real need and a refresh contract exists.
- Every migration is ordered, transactional where PostgreSQL permits, tested on an empty database and on a copy of the previous schema, and never edited after release.
