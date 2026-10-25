# PostgreSQL container

The root `compose.yml` mounts `server/migrations/000001_initial.up.sql` into PostgreSQL's one-time initialization directory. For an existing database, use a migration tool instead of replaying the bootstrap schema.
