---
name: goshipkit-docs-sync
description: Audit and update GoShipKit documentation when code, schema, configuration, product behavior, repository structure, operations, or agent workflows change. Use before final verification for implementation tasks; for audit-only requests, report gaps without editing.
---

# GoShipKit documentation sync

Keep documentation aligned with the delivered behavior. Do not add speculative
features or document deferred scope as implemented.

## Workflow

1. Read `AGENTS.md`, `docs/README.md`, and the documents relevant to the changed
   paths. Inspect staged, unstaged, and untracked changes.
2. Build a short inventory of changed behavior, contracts, configuration,
   structure, operational steps, and durable decisions.
3. Map each item to the existing documentation owner:

   | Change | Documentation owner |
   |---|---|
   | Product scope or acceptance behavior | `docs/product/` |
   | Runtime boundaries or durable trade-offs | `docs/architecture/` and ADRs |
   | Repository paths or ownership | `README.md` and `docs/architecture/repository-structure.md` |
   | UI tokens or cross-client interaction | `docs/design/` |
   | Reusable implementation rule | `docs/technique/` |
   | Deployment, recovery, migration, or operator action | `docs/runbooks/` |
   | Local setup or environment variables | `.env.example`, root README, and `docs/development/` |
   | Agent skill or workflow | `docs/technique/codex-skills.md` and `AGENTS.md` when mandatory |

4. Update the smallest authoritative set of files. Link to a canonical document
   instead of copying the same rule into several places.
5. Check examples, paths, commands, defaults, and local Markdown links against
   the repository. Preserve the concise self-hosting focus of the root README.
6. Run `$goshipkit-change-verification` after documentation is stable.

For an audit-only request, return file-and-line evidence plus proposed target
documents, and do not mutate files. Documentation updates do not authorize a
product, schema, dependency, or deployment change that the user did not request.
