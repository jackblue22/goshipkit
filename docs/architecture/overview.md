# Architecture overview

## Decision

GoShipKit starts as a modular monolith with multiple clients:

```text
React web ─────┐
Wails desktop ─┼── HTTPS / JSON API ── Go + Chi ── PostgreSQL
Flutter mobile ┘                         │
                                        └── provider adapters / background jobs
```

The desktop application is a client, not a second server. It may later add native notifications, deep links, filesystem helpers, and offline caching. Business rules stay in the API.

## Boundaries

Backend packages are grouped by business capability (`auth`, `workspace`, `project`, `task`, `milestone`, `resource`, `update`, `feedback`, `portal`, and so on). HTTP, configuration, database adapters, telemetry, and job infrastructure live under `internal/platform`.

PostgreSQL is the source of truth. A PostgreSQL-backed job table is sufficient for early background work; Redis, Kafka, Elasticsearch, a graph database, and Kubernetes are intentionally excluded until demonstrated load requires them.

## Contracts

- Public endpoints live under `/api/v1`.
- An OpenAPI description will become the source of truth before feature endpoints are implemented.
- Browser and desktop share React components, but not server-side domain models.
- Flutter consumes the same HTTP contract and implements native UI.

## Security model

Authorization combines membership role, project scope, explicit capability, and resource visibility. External stakeholder content is private by default and published deliberately. Provider secrets must be encrypted at the application layer; share and invitation tokens are stored only as hashes.

## Deployment

The initial self-host target is one Linux host running Docker Compose. PostgreSQL uses a persistent volume. Production deployments should terminate TLS at a reverse proxy and use managed secrets, scheduled backups, and off-host backup retention.
