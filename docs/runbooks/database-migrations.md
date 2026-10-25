# Database migration runbook

## Before applying

- Back up and restore-test the target database.
- Read every pending migration and identify locks, rewrites, and application compatibility.
- Confirm `schema_migrations` and compare the applied versions with the release manifest.
- Stop API/workers when a migration is not backward compatible.

## Fresh installations

The Compose init directory runs ordered `*.sql` files only when PostgreSQL creates an empty data volume. Adding a migration does not update an existing volume automatically.

## Existing installations

Until a dedicated migration binary is implemented, copy and execute one reviewed migration at a time:

```bash
docker compose cp server/migrations/000002_database_invariants.up.sql postgres:/tmp/migration.sql
docker compose exec postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /tmp/migration.sql'
docker compose exec postgres rm -f /tmp/migration.sql
```

Never rerun a migration already recorded in `goshipkit.schema_migrations`. Prefer a forward corrective migration over editing or rolling back an applied migration.

## Verify

- Confirm the new migration record.
- Run API health and a representative create/read/update flow.
- Check PostgreSQL logs and slow queries.
- Restart workers and confirm job claims and webhook processing.
