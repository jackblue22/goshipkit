# GoShipKit

GoShipKit is a lightweight, self-hosted project hub for small teams. It keeps projects, tasks, milestones, resource links, progress updates, and stakeholder feedback in one approachable workspace without trying to replace Git hosting, cloud drives, design tools, or CI/CD systems.

> Status: early foundation. The repository currently contains the architecture skeleton, product scope, and database bootstrap schema—not a production-ready release.

## Product direction

- Designed first for teams of 2–5 people and usable by teams up to roughly 10.
- Friendly views for members, mentors, clients, and investors with project-scoped access.
- Web-first and responsive; Flutter mobile and Wails desktop are secondary clients.
- Links to GitHub, Drive, Figma, Notion, demos, and other tools before adding deep integrations.
- Self-hosted as a Go modular monolith backed by PostgreSQL.

See [features.md](features.md) for the phased product scope and [docs/architecture/overview.md](docs/architecture/overview.md) for technical boundaries.

## Repository layout

```text
apps/
  web/                 React + Vite + TypeScript
  mobile/              Flutter + Dart
  desktop/             Wails + shared React packages
server/                Go + Chi modular monolith
packages/
  api-client/          TypeScript API client (generated later from OpenAPI)
  shared-types/        Client-only shared types
  ui/                  Shared React UI for web and desktop
  config/              Shared TypeScript configuration
docs/                  Product, architecture, and development docs
deploy/docker/         Container-specific deployment material
```

## Quick start

Prerequisites: Node.js 22+, pnpm 10+, Go 1.25+, Flutter 3.29+, Docker with Compose, and Wails CLI v2 for desktop development.

```bash
cp .env.example .env
# Set POSTGRES_PASSWORD in .env.
corepack pnpm install
corepack pnpm dev:web
```

In another terminal, run `go run ./cmd/api` from `server/`. Alternatively, `docker compose up --build` starts PostgreSQL and the API together. The initial probes are `GET /healthz` and `GET /api/v1/`.

Useful checks are `corepack pnpm build`, `corepack pnpm typecheck`, `go test ./...` from `server/`, and `flutter test` from `apps/mobile/`.

## License

GoShipKit is licensed under the [PolyForm Perimeter License 1.0.1](LICENSE). This license restricts using the software to offer a competing product. Because of that restriction, GoShipKit is **source-available**, not OSI-approved open source. Review the license before using or distributing the software.
