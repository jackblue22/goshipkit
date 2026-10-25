# Engineering techniques

This directory contains reusable implementation guidance. It complements ADRs (why a durable decision was made) and runbooks (how to operate or recover the system).

- [Authorization and visibility](authorization-and-visibility.md)
- [Progress calculation](progress-calculation.md)
- [Reliable background jobs](reliable-background-jobs.md)
- [PostgreSQL conventions](postgresql-conventions.md)
- [Codex skills](codex-skills.md)

Add a technique document when several features need the same non-obvious algorithm or safety pattern. Do not put product requirements here; those belong in `docs/product` or `docs/srs`.
