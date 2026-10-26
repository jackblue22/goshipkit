# Codex skills for GoShipKit

Codex skills are installed outside this repository. On the current Windows
workstation:

- user and system skills: `C:\Users\PC\.codex\skills\`;
- plugin-provided skills: `C:\Users\PC\.codex\plugins\cache\`;
- GoShipKit skill: `C:\Users\PC\.codex\skills\goshipkit-development\SKILL.md`.

Project rules in `AGENTS.md` and the design contract in
`docs/design/DESIGN.md` override generic third-party guidance when they differ.
Installing a skill does not authorize adding its suggested dependencies or
changing product architecture.

## Repository-local Codex skills

These skills are versioned with GoShipKit under `.agents/skills/` so every
contributor and Codex session uses the same project-specific workflow:

- `goshipkit-change-verification` selects final checks from changed paths and
  provides a cross-platform Python verifier;
- `goshipkit-docs-sync` maps behavior, schema, configuration, structure, and
  operational changes to their authoritative documentation.

`AGENTS.md` requires both workflows when their trigger applies. They adapt the
Codex-native pattern used by OpenAI repositories without copying repository-
specific Python SDK commands or CI assumptions.

## Project-focused skills

### Delivery mindset

- `systematic-debugging`
- `verification-before-completion`
- `receiving-code-review`

Source: `obra/superpowers`, pinned to
`2ce8aa15d05bd57213e6f746f953aafb7ded7a8b`.

### UI, React, and motion

- `ui-ux-pro-max`
- `composition-patterns`
- `react-best-practices`
- `gsap-core`
- `gsap-react`
- `gsap-performance`
- `gsap-timeline`
- `gsap-scrolltrigger`

Sources:

- `nextlevelbuilder/ui-ux-pro-max-skill` at
  `d14efff8ed1faa4187f004f79926f428c8074ec7`;
- `vercel-labs/agent-skills` at
  `063bee94c3f4df8453406c830b0a7df0f2860278`;
- `greensock/gsap-skills` at
  `aed9cfd3277740755f6bfc1155c7aa645403b760`.

GSAP guidance applies only when motion is justified on React web/desktop. It
does not make GSAP a default dependency and does not apply to Flutter.

### Flutter mobile

- `flutter-apply-architecture-best-practices`
- `flutter-build-responsive-layout`
- `flutter-fix-layout-issues`
- `flutter-setup-declarative-routing`
- `flutter-setup-localization`
- `flutter-add-widget-test`
- `flutter-add-integration-test`

Source: `flutter/agent-plugins`, pinned to
`f813a46b18456a20f37eb5784c091b7d945c3b4b`.

### Go backend

- `golang-code-style`
- `golang-error-handling`
- `golang-context`
- `golang-testing`
- `golang-database`
- `golang-security`
- `golang-troubleshooting`
- `golang-observability`
- `golang-lint`
- `golang-dependency-management`
- `golang-concurrency`
- `golang-safety`
- `golang-design-patterns`
- `golang-structs-interfaces`
- `golang-benchmark`
- `golang-gopls`

Source: `samber/cc-skills-golang`, pinned to
`246b6c4c1ab3077dee114beb9ade3bb0527dfebc`.

These skills provide Go techniques; GoShipKit remains a Go/Chi modular
monolith and does not adopt a library merely because a skill mentions it.
The repository quality gates remain authoritative; in particular, generic
skill instructions cannot create CI workflows, require sub-agents, add a Go
dependency, or restructure packages without task-specific justification.

`golang-testing` covers standard-library and table-driven unit tests, HTTP
handler tests with `httptest`, integration-test build tags, race detection,
fuzzing, and coverage analysis. GoShipKit does not install a separate testing
framework skill by default: `testing` and `httptest` are sufficient until a
specific test problem justifies another dependency.

### PostgreSQL

- `supabase-postgres-best-practices`

Source: `supabase/agent-skills`, pinned to
`c9be0e931b7930f7d02126d04774d904c381e7d7`.
The skill is applicable to self-hosted PostgreSQL and does not require Supabase.

## Existing supporting skills

- `goshipkit-development` — repository routing and product/security invariants.
- `figma-use` — required before programmatic Figma operations.
- `playwright` — rendered browser-flow and responsive verification.
- `sentry` — read-only production error diagnosis when connected.
- `gh-address-comments` and `gh-fix-ci` — pull-request maintenance.
- `security-best-practices` and `security-threat-model` — explicit security work.
- `pdf` — validate generated stakeholder reports.
- system skills such as `imagegen`, `openai-docs`, `skill-creator`,
  `skill-installer`, and `plugin-creator` are maintained by Codex.

## Audit decisions

The approved repositories were reviewed before installation. The following
candidates were deliberately not installed:

- `test-driven-development` because it instructs the agent to delete valid
  implementation written before a test;
- Vercel `web-design-guidelines` and `writing-guidelines` because they download
  unpinned instructions at invocation time;
- the generic `api-design-principles` skill because its executable example is
  FastAPI-oriented and conflicts with GoShipKit's Go/Chi boundary;
- meta orchestration/subagent packs because they unnecessarily override the
  host agent's workflow.

Additional Go candidates were also excluded deliberately:

- `golang-modernize` currently targets language/library guidance newer than
  GoShipKit's Go 1.25 module;
- `golang-continuous-integration` can generate workflow files, while the
  repository owner explicitly owns `.github/workflows`;
- `golang-project-layout` could compete with the established modular-monolith
  boundaries;
- `golang-stretchr-testify` would encourage a test dependency before the
  standard library has proved insufficient;
- `golang-refactoring` imposes a heavyweight multi-agent/worktree workflow;
- `golang-naming` contains rigid preferences that are not all project policy;
- framework-specific gRPC, GraphQL, CLI, and dependency-injection skills do
  not match the current Go/Chi REST service.

`ui-ux-pro-max` contains local Python search scripts. They do not execute
network or child processes in normal use. Persistence is opt-in and refuses to
overwrite an existing master design file unless `--force` is explicitly used.

## Updating skills

Treat third-party skills as executable supply-chain inputs:

1. review the upstream diff and all scripts;
2. pin the approved commit rather than installing a moving branch;
3. install only the required skill directories, not an entire collection;
4. update this manifest with the new commit;
5. restart Codex or begin a new turn so the installed skills are discovered.
