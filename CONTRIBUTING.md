# Contributing to GoShipKit

Thank you for helping make small-team project work easier to understand.

## Before starting

1. Search existing issues and keep each change focused on one problem.
2. For significant product or schema changes, open a proposal first and describe the user outcome, permission impact, and migration path.
3. Preserve the product boundary: GoShipKit links to specialist tools; it does not replace Git hosting, cloud storage, an IDE, or a CI runner.

Use short-lived branches such as `feat/GSK-123-short-description`, `fix/GSK-123-short-description`, or `docs/GSK-123-short-description`.

Run the relevant checks before opening a pull request:

```bash
corepack pnpm typecheck
corepack pnpm build
(cd server && go test ./...)
(cd apps/mobile && flutter test)
```

Do not commit generated output, credentials, local `.env` files, database dumps, or Codex state. Update `.env.example` whenever a public environment variable is added.

## Architecture rules

- Domain logic belongs in `server/internal/<module>`, not HTTP handlers.
- Database access must be workspace/project scoped where applicable.
- Internal content is private by default; stakeholder visibility is explicit and enforced by the API.
- After the initial baseline, database changes need a forward migration under `server/migrations/`.
- Shared React components belong in `packages/ui`; mobile UI remains native Flutter.
- OpenAPI will be the source for generated clients; do not hand-copy server DTOs into shared client types.

Pull requests should explain the user outcome, link the issue, identify permission/schema effects, and provide test evidence. By contributing, you agree that your contribution is licensed under this repository's license.
