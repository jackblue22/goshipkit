# PostgreSQL backup and restore

## Backup

Create a host backup directory, then produce a custom-format dump inside the container and copy it out:

```bash
mkdir -p backups
docker compose exec postgres sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --file=/tmp/goshipkit.dump'
docker compose cp postgres:/tmp/goshipkit.dump ./backups/goshipkit.dump
docker compose exec postgres rm -f /tmp/goshipkit.dump
```

Store the dump off-host with restricted access. A backup is not valid until a restore test succeeds.

## Restore test

1. Stop API writes: `docker compose stop api`.
2. Restore into a separate empty test database; do not overwrite production for a routine verification.
3. Copy and restore the dump:

```bash
docker compose exec postgres createdb -U "$POSTGRES_USER" goshipkit_restore_test
docker compose cp ./backups/goshipkit.dump postgres:/tmp/goshipkit.dump
docker compose exec postgres sh -c 'pg_restore -U "$POSTGRES_USER" -d goshipkit_restore_test --clean --if-exists /tmp/goshipkit.dump'
docker compose exec postgres rm -f /tmp/goshipkit.dump
```

4. Verify table counts, recent projects, memberships, and a representative portal visibility query.
5. Drop only the confirmed test database and restart the API.

Record backup time, application version, migration version, restore duration, and verification result.
