---
name: goshipkit-change-verification
description: Select and run final verification for GoShipKit changes across Go, PostgreSQL, React/Vite, Wails, Flutter, Compose, and documentation. Use after a task diff is stable and before claiming completion or committing; do not use for read-only analysis.
---

# GoShipKit change verification

Verify the delivered state, not an earlier revision. Preserve user-owned changes
and never create or edit `.github/workflows`.

## Workflow

1. Read the applicable `AGENTS.md` and inspect staged, unstaged, and untracked
   paths. Do not infer scope from the last commit alone.
2. If behavior, configuration, schema, repository structure, or operator steps
   changed, apply `$goshipkit-docs-sync` before final verification.
3. During implementation, run focused checks for the touched area. When the
   task diff is stable, run the repository verifier from the root:

   ```text
   python .agents/skills/goshipkit-change-verification/scripts/verify.py
   ```

   With a clean worktree or when checking a committed change, pass one or more
   explicit scopes: `docs`, `server`, `web`, `desktop`, `mobile`, `compose`, or
   `all`.
4. Database migrations additionally require the clean-database replay and
   upgrade-path procedure in `docs/runbooks/database-migrations.md`. The script
   cannot replace that stateful check.
5. If a required tool or service is unavailable, report the exact missing gate.
   Never describe an unrun, skipped, or failed command as passing.
6. Commit only after the applicable checks pass and documentation is synchronized.

## Scope expectations

- `docs`: whitespace plus local Markdown links.
- `server`: `go vet ./...` and `go test ./...` under `server`.
- `web`: monorepo TypeScript typecheck and build.
- `desktop`: Wails Go tests plus the shared TypeScript checks.
- `mobile`: Flutter analyze and test.
- `compose`: Docker Compose configuration validation.

Add `go test -race ./...`, security tooling, benchmarks, browser checks, or
PostgreSQL replay when the changed risk boundary requires them. Passing the
base script does not waive those task-specific gates.
