# PostgreSQL container

The root `compose.yml` mounts `server/migrations/` into PostgreSQL's one-time
initialization directory. A fresh database runs every `*.sql` file in lexical
order. For an existing database, use a migration tool or the controlled process
in `docs/runbooks/database-migrations.md` instead of replaying the bootstrap.
