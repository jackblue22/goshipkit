# Backend quality gates

These gates keep GoShipKit's Go/Chi backend reviewable as implementation is
accelerated with coding agents. Tests are executable contracts, not a target
coverage percentage. Choose the smallest test that proves the behavior, then
add broader tests where a boundary or failure mode requires them.

## Required test layers

| Change | Minimum evidence |
|---|---|
| Pure domain rule | Table-driven unit tests for success, boundary, and error cases |
| HTTP route or handler | `httptest` coverage of status, response contract, invalid input, and authorization |
| Authorization or visibility | Allowed, denied, cross-project, and unpublished-content cases |
| PostgreSQL query or repository | Integration test against PostgreSQL, including tenant/project isolation |
| Migration or database invariant | Fresh schema replay plus an upgrade-path check from the prior schema |
| Background job or webhook | Idempotency, retry, duplicate delivery, and terminal-failure tests |
| Concurrent or shared state | Deterministic lifecycle tests and `go test -race ./...` |
| Bug fix | A regression test that fails before the fix and passes afterward |
| Performance change | Stable benchmark baseline and before/after comparison on the same toolchain |

Generated code and trivial declarations do not need artificial unit tests.
Their generator, contract, compile check, or consuming behavior should be
tested instead.

## Default Go test style

- Prefer the standard `testing` package and `net/http/httptest`.
- Use named table cases when several inputs share the same contract.
- Assert observable results, stored state, emitted events, and public error
  categories rather than private implementation details.
- Keep unit tests deterministic and independent of execution order.
- Use `t.Parallel()` only after confirming the test owns its mutable state and
  database fixtures.
- Avoid time-based sleeps. Inject clocks or use deterministic synchronization.
- Define interfaces at the consumer boundary only when substitution is needed;
  do not create interfaces solely to make every type mockable.
- Prefer small fakes for project-owned interfaces. Introduce a mock library only
  when repeated hand-written fakes are demonstrably harder to maintain.

## Database integration policy

Database behavior cannot be proven only with mocks. Test real PostgreSQL for:

- foreign keys, unique constraints, checks, triggers, and transaction behavior;
- authorization predicates and project/workspace scoping;
- queries involving nullability, time zones, ordering, locking, or pagination;
- migration replay and invariants documented in
  `docs/technique/postgresql-conventions.md`.

Integration tests should use isolated schemas or databases and clean up their
own fixtures. Never point automated tests at a developer or production
database. Tests that require PostgreSQL should use the `integration` build tag
until the repository provides a dedicated integration-test command.

## Verification matrix

Run commands from `server/` unless noted otherwise.

```text
Every Go change                gofmt on changed files
Every Go change                go vet ./...
Every Go change                go test ./...
Concurrency/shared state       go test -race ./...
Dependency change              go mod tidy
Dependency change              go mod verify
Dependency/security review     govulncheck ./...       (when installed)
Lint policy                    golangci-lint run ./... (when configured)
Performance claim              go test -bench=. -benchmem ./...
Database change                replay server/migrations on clean PostgreSQL
```

Do not install a missing tool silently or replace a pinned version with
`@latest`. Tool adoption belongs in a reviewed dependency/tooling change.

## Review gate

Before committing a backend change, verify:

1. The implementation stays inside the owning `server/internal/<domain>` or
   `server/internal/platform` boundary.
2. Tests cover the failure and permission paths, not only the happy path.
3. Logs and errors do not expose secrets, tokens, private content, or raw SQL
   parameters containing personal data.
4. New goroutines, queues, retries, queries, and buffers are bounded and have a
   clear shutdown or cancellation path.
5. New dependencies are necessary, maintained, license-compatible, and visible
   in the reviewed `go.mod`/`go.sum` diff.
6. Related OpenAPI, migration, ADR, runbook, README, or technique documentation
   is updated in the same logical commit.

If a required check cannot run locally, record exactly which check was skipped
and why. A missing tool is not evidence that the change passes.
