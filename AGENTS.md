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
