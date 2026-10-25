# Migrations

`/goshipkit.sql` is the pre-release bootstrap schema and current data-model reference. Before the first distributable release, snapshot it here as the baseline migration. Every later schema change must be an ordered, forward-only migration with a documented rollback or recovery procedure.
