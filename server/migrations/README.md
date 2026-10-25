# Migrations

Migrations are ordered and forward-only:

- `000001_initial.up.sql` creates the pre-release bootstrap schema.
- `000002_database_invariants.up.sql` adds traceable requirements, project-scope
  guards, progress views, audit immutability, and safe background-job leasing.

Docker Compose executes all `*.sql` files in this directory, in lexical order,
only when PostgreSQL initializes an empty data volume. Existing databases need a
real migration runner or an operator-controlled `psql` migration. Never edit an
already released migration; follow the recovery process in
`docs/runbooks/database-migrations.md`.
