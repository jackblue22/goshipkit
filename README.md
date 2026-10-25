# GoShipKit

GoShipKit is a lightweight, self-hosted project hub for small teams. It keeps projects, tasks, milestones, resource links, progress updates, and stakeholder feedback in one approachable workspace without trying to replace Git hosting, cloud drives, design tools, or CI/CD systems.

> Status: early foundation. The repository currently contains the architecture skeleton, product scope, and database bootstrap schema—not a production-ready release.

## Product direction

- Designed first for teams of 2–5 people and usable by teams up to roughly 10.
- Friendly views for members, mentors, clients, and investors with project-scoped access.
- Web-first and responsive; Flutter mobile and Wails desktop are secondary clients.
- Links to GitHub, Drive, Figma, Notion, demos, and other tools before adding deep integrations.
- Self-hosted as a Go modular monolith backed by PostgreSQL.

See [docs/product/features.md](docs/product/features.md) for the phased product scope and [docs/architecture/overview.md](docs/architecture/overview.md) for technical boundaries.

## Repository layout

```text
goshipkit/
├── apps/                         # Deployable clients
│   ├── web/                      # React + Vite + TypeScript
│   ├── mobile/                   # Flutter for Android and iOS
│   └── desktop/                  # Wails host + React frontend
├── server/                       # Go + Chi modular monolith
│   ├── cmd/api/                  # API entry point
│   ├── internal/
│   │   ├── auth/                 # Identity and sessions
│   │   ├── project/              # Project lifecycle and membership
│   │   ├── task/                 # Work items, boards, workflows
│   │   ├── portal/               # Mentor/client/investor projections
│   │   └── platform/             # HTTP, database, crypto, jobs, telemetry
│   └── migrations/               # Ordered PostgreSQL migrations
├── packages/                     # Shared TypeScript packages
│   ├── api-client/               # Future OpenAPI-generated client
│   ├── shared-types/             # Client-side shared types
│   ├── ui/                       # Shared React UI for web and desktop
│   └── config/                   # Shared TypeScript configuration
├── docs/                         # Product, architecture, and development docs
├── deploy/docker/                # Container deployment assets
├── compose.yml                   # Self-host stack entry point
├── go.work                       # Server + desktop Go workspace
└── pnpm-workspace.yaml           # JavaScript/TypeScript workspace
```

See the complete ownership map in [docs/architecture/repository-structure.md](docs/architecture/repository-structure.md).

## Self-host preview

The current Compose stack starts the Go API and PostgreSQL. GoShipKit is still an early foundation: the production web image, TLS proxy, automated backups, and upgrade tooling are not shipped yet.

### Prepare

- A Linux host, macOS, or Windows with Docker Desktop/Engine and Docker Compose v2.
- Git and at least one free local port: `8080` for the API. PostgreSQL is bound to local port `5432` by default.
- A strong, unique PostgreSQL password. Do not reuse the example value or commit `.env`.

```bash
git clone https://github.com/jackblue22/goshipkit.git
cd goshipkit
cp .env.example .env
```

On PowerShell, use `Copy-Item .env.example .env`. Open `.env` and replace `POSTGRES_PASSWORD=change-me` before starting.

### Start and verify

```bash
docker compose up -d --build
docker compose ps
curl http://localhost:8080/healthz
```

A healthy API returns `{"status":"ok"}`. View startup errors with `docker compose logs -f api postgres`.

Database data persists in the named `postgres-data` volume. `docker compose down` stops the stack without deleting it. **Do not run `docker compose down -v` unless you intentionally want to delete all local database data.** The initial SQL migration runs only when PostgreSQL creates a new empty volume.

Before exposing an installation publicly, place a TLS reverse proxy in front of the API, keep PostgreSQL private, use managed secrets, and configure tested off-host backups. See [docs/development/getting-started.md](docs/development/getting-started.md) for development notes.

## Develop from source

Install only the toolchains for the clients you work on:

- Web/shared packages: Node.js 22+ with Corepack/pnpm 10+.
- API: Go 1.25+ and PostgreSQL 15+ or Docker Compose.
- Mobile: Flutter 3.29+ with the Android/iOS platform toolchains.
- Desktop: Go 1.25+, Node.js 22+, and Wails CLI v2.

```bash
corepack pnpm install
corepack pnpm dev:web
```

In another terminal, run `go run ./cmd/api` from `server/`. The initial probes are `GET /healthz` and `GET /api/v1/`.

Useful checks are `corepack pnpm build`, `corepack pnpm typecheck`, `go test ./...` from `server/`, and `flutter test` from `apps/mobile/`.

## License

GoShipKit is licensed under the [PolyForm Perimeter License 1.0.1](LICENSE.md). This license restricts using the software to offer a competing product. Because of that restriction, GoShipKit is **source-available**, not OSI-approved open source. Review the license before using or distributing the software.
