# Section IV scope review

This note records the implementation reading of `tasks.md` section IV. Where
the early all-in-one wording conflicts with its later clarification, the later
small-team project-hub scope wins.

## Product boundary

GoShipKit is a self-hosted collaboration hub for teams of roughly 2–10. The
first useful release joins projects, tasks, milestones, resources, progress,
updates, comments, and explicitly published stakeholder views. It links to Git,
design, document, demo, and deployment providers; it does not replace them.

The following are not MVP responsibilities: Git hosting, source editing, a CI
runner, generic cloud storage, Kubernetes, Kafka, microservices, or a graph
database. Their tables or extension points do not mean the feature is shipped.

## Items that need explicit implementation care

1. Authorization must be project-scoped on every API query. Workspace
   membership alone is insufficient, and frontend hiding is not authorization.
2. Stakeholder projections are allowlists. Draft updates and ungranted entities
   remain private; external URLs never grant provider access.
3. Progress is completed eligible tasks divided by total eligible tasks.
   Cancelled and archived work is excluded, and the metric is not a measure of
   effort or individual performance.
4. Writes that create activity, notifications, webhooks, or sync jobs use a
   transactional outbox/job row so side effects cannot be lost after commit.
5. Provider sync needs signature verification, idempotency, bounded retry,
   dead-letter handling, rate-limit awareness, and periodic reconciliation.
6. Export, retention, backup/restore, audit, health, structured logs, secret
   rotation, i18n, accessibility, and responsive layouts are release work—not
   polish to postpone indefinitely.
7. Web is the primary responsive client. Flutter and Wails consume the same API;
   desktop is a client shell, not a second backend.

## Delivery order

- Foundation: identity, workspaces/projects, active membership, authorization,
  health, migrations, backup/restore, and audit.
- Core collaboration: tasks/boards, milestones, resources, comments, activity,
  and the shared progress definition.
- Stakeholder experience: published updates, visibility grants, feedback, and
  safe export/share flows.
- Integrations: provider links first, then read-only metadata synchronization;
  deeper automation only after idempotency and recovery are proven.
- Advanced roadmap: revision-specific stakeholder acceptance, post-acceptance
  bug/change-request traceability, QA, reporting, automation, and
  provider-specific enhancements based on observed demand. Internal task
  `Done` never substitutes for an authorized stakeholder decision.

## Remaining release gates

- Freeze a role/capability matrix and test both allowed and denied routes.
- Define archival, deletion, export, audit retention, and recovery objectives.
- Add migration upgrade tests from the previous release, not only empty-schema
  tests.
- Verify responsive keyboard-accessible flows and Vietnamese/English copy.
- Exercise stakeholder leakage tests across search, feeds, notifications,
  exports, and background jobs.
- Load-test the project board and portal with representative small-team data;
  optimize from measurements rather than adding infrastructure in advance.
