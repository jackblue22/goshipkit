# GoShipKit repository guidance

GoShipKit is a simple self-hosted project hub for teams of 2–10. Do not turn it into a Git host, IDE, CI/CD runner, general cloud drive, or enterprise-first project suite.

## Routing

- `apps/web`: React + Vite browser client.
- `apps/mobile`: Flutter client; do not introduce React Native or Expo.
- `apps/desktop`: Wails host and React frontend; reuse `packages/ui`.
- `server`: Go + Chi modular monolith. Business logic lives in `internal/<domain>` and transport/infrastructure in `internal/platform`.
- `packages/api-client`: generated-client boundary; prefer OpenAPI over handwritten endpoint duplication.
- `server/migrations/`: ordered, forward-only PostgreSQL schema history.

## Invariants

- Project and stakeholder roles are project-scoped; workspace membership alone must not reveal private project data.
- Stakeholder-visible content defaults to internal and needs explicit publication/visibility.
- External resource links do not grant access to the linked service.
- API authorization is mandatory; hiding frontend controls is not authorization.
- Preserve public identifiers and use UTC `timestamptz` timestamps.
- Do not write files under `.github/workflows`; the maintainer owns CI.

## Backend quality gates

- New backend behavior needs tests at the narrowest useful boundary. Bug fixes
  need a regression test unless the failure cannot be reproduced locally.
- Authorization and visibility changes must cover allowed access, denied
  access, cross-project isolation, and unpublished-content isolation.
- Prefer standard-library table tests and `httptest`; add a test dependency
  only when its maintenance cost is justified.
- Run `go test ./...` for every Go change. Add `go test -race ./...` for
  concurrency or shared-state changes, and replay migrations for schema work.
- Dependency changes require `go mod tidy`, `go mod verify`, and a reviewed
  `go.mod`/`go.sum` diff. Run `govulncheck ./...` when the tool is available.
- Do not optimize from intuition. Record a reproducible benchmark before and
  after a performance change.
- Follow `docs/technique/backend-quality-gates.md` for the risk-based test and
  verification matrix.
