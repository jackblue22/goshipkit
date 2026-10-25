# ADR-0002: Application authorization with database integrity guards

- Status: accepted
- Date: 2026-10-26

## Context

Project-scoped stakeholder access is a core invariant. PostgreSQL row-level security can add defense in depth, but it requires reliable per-request identity propagation across pooled connections and separate policies for workers and migrations.

## Decision

The Go permission module is authoritative for roles, capabilities, and publication policy. Queries begin from the actor's authorized project set. PostgreSQL foreign keys and triggers reject cross-project references and invalid publication links. RLS is deferred until the authentication and connection-pool design is implemented and tested.

## Consequences

Every repository/API path needs authorization tests, including search, exports, notifications, and background jobs. Enabling RLS is a release gate for a future shared multi-tenant hosted offering, not required for a single-tenant self-host MVP.
