# Repository structure and boundaries

## Top-level layout

```text
goshipkit/
├── apps/                     Deployable user clients
│   ├── web/                  React + Vite browser app
│   ├── mobile/               Flutter iOS/Android app
│   └── desktop/              Wails host + React frontend
├── server/                   Go + Chi modular monolith
│   ├── cmd/api/              API composition root
│   ├── internal/             Domain and platform packages
│   └── migrations/           Ordered PostgreSQL migrations
├── packages/                 Shared TypeScript packages, not deployables
├── docs/                     Product, architecture, SRS, and development docs
├── deploy/                   Container and deployment assets
└── .github/                  Issue/community metadata; workflows owner-managed
```

## Why some files stay at the root

| File | Why it belongs at root |
|---|---|
| `package.json` | Runs commands across all JavaScript/TypeScript workspaces. Each app/package still owns its own package manifest. |
| `pnpm-workspace.yaml` | Defines the workspace boundary; pnpm discovers it from the repository root. |
| `pnpm-lock.yaml` | One deterministic dependency graph for the whole monorepo. Per-app lockfiles would allow incompatible installations. |
| `go.work` | Connects the independent Go modules in `server` and `apps/desktop` for local development. Each retains its own `go.mod`. |
| `compose.yml` | Provides the conventional one-command entry point for the complete self-host stack. Executable container details remain under `deploy/`. |
| `.env.example` | Documents the environment contract consumed by the root Compose stack and local services. |
| `README.md`, `LICENSE.md`, `CONTRIBUTING.md`, `SECURITY.md` | Repository-wide files GitHub and contributors expect to discover at the top level. |
| `AGENTS.md` | Repository-wide instructions that coding agents must discover before entering a subdirectory. |

Moving these files into individual apps would either duplicate global state or stop the corresponding workspace tool from coordinating the monorepo.

## Backend module ownership

| Module | Owns | Must not own |
|---|---|---|
| `auth` | Accounts, sessions, credentials, MFA | Project authorization decisions |
| `workspace` | Workspaces, workspace membership | Implicit access to every project |
| `project` | Project lifecycle and membership | Tasks or stakeholder publication content |
| `task` | Work items, workflows, boards, labels, dependencies | Git provider synchronization |
| `milestone` | Milestones, releases, deliverables, acceptance | Generic task transitions |
| `resource` | External resource-link metadata | Permissions at the external provider |
| `update` | Draft/published progress updates and revisions | Portal-wide authorization |
| `feedback` | Review/feedback threads and change requests | Membership administration |
| `portal` | Stakeholder projections and publication experience | Duplicate client/mentor/investor backends |
| `permission` | Project role, capability, and visibility evaluation | UI-only enforcement |
| `integration` | Provider connections, webhooks, metadata sync | Hosting Git or executing CI |
| `notification` | Preferences and delivery orchestration | Domain decisions that generate events |
| `report` | Exports and analytics projections | Source-of-truth domain state |
| `search` | Authorized search projection/querying | Returning records before permission filters |
| `audit` | Append-only material/security events | Mutable activity state |
| `knowledge` | Documents, diagrams, revisions, entity links | External provider synchronization |
| `automation` | Opt-in event/condition/action rules | Unconfirmed privileged mutations |
| `quality` | Test cases, suites, runs, and evidence | Executing automated test infrastructure |
| `platform/*` | HTTP, config, database, cryptography, jobs, telemetry | Product rules |

Modules may call another module through explicit application interfaces. They must not import another module's database implementation or mutate its tables as a shortcut.

## Client boundaries

- Web owns the primary responsive experience.
- Desktop reuses React UI where useful and adds only native shell capabilities; it talks to the same server.
- Mobile implements native Flutter UI and consumes the same API contract.
- `packages/ui` is React-only and therefore is not shared with Flutter.
- `packages/shared-types` contains client concerns, not Go domain models.
- `packages/api-client` becomes generated output from OpenAPI when feature endpoints begin.

No client performs authoritative permission checks or calculates canonical progress. Those decisions remain server-side.
