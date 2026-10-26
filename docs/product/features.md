# GoShipKit product features

Status: product scope v0.1  
Primary audience: teams of 2–5 people; initial supported ceiling: about 10 people per workspace  
Positioning: a simple, self-hosted project hub that helps members and external stakeholders understand work and progress without requiring Git, Scrum, or DevOps expertise.

## Product principles

1. **Simple by default.** A new team starts with Projects, My Tasks, Calendar, and Team—not an enterprise configuration maze.
2. **Useful without Git.** Research, design, study, and business projects must work without connecting a repository.
3. **Link before replacing.** GoShipKit links to GitHub, Drive, Figma, Notion, demos, and diagrams. It does not become those products.
4. **Private by default.** Mentor, client, and investor access is project-scoped. Content appears externally only when the team publishes it.
5. **Progress is explainable.** MVP progress is completed tasks divided by eligible tasks, clearly labelled “task completion,” not effort consumed.
6. **One stakeholder engine.** Client, mentor, and investor portals are presets over the same access and publication model, not separate products.
7. **Web first.** Responsive web is the primary client. Mobile and desktop follow the same API and are not separate backends.

## How task IV was reconciled

Task IV contains two product directions from different moments in the discussion. The later clarification—GoShipKit as a simple hub for teams under 10, especially 2–5 people—takes precedence over the earlier all-in-one engineering workspace proposal.

- Retained: multi-project overview, tasks, resources, milestones, progress updates, mentor/client/investor views, explicit visibility, lightweight traceability, Git metadata, documents, diagrams, notifications, reports, and self-hosting.
- Simplified: traceability uses generic links in PostgreSQL; Git integration stores metadata; stakeholder experiences share one portal engine; the initial workflow stays understandable without Scrum.
- Deferred to L2/L3: full Scrum, QA suites, provider integrations, automation, AI assistance, advanced analytics, OIDC/SSO, plugin SDK, and offline synchronization.
- Removed from the product boundary: Git hosting, IDE/editor, CI runner, registry, deployment engine, mandatory Git workflows, early microservices, Kafka, Kubernetes, graph databases, and autonomous code-changing agents.

This precedence rule is why some ideas appearing early in task IV remain as optional L3 capabilities rather than MVP requirements.

## Roles and visibility

### Roles

| Role | Scope | Primary abilities |
|---|---|---|
| Workspace owner | Workspace | Workspace settings, billing-ready administration, all projects by explicit policy |
| Workspace admin | Workspace | Members and workspace configuration; project access remains auditable |
| Project owner | Project | Project settings, membership, visibility, publication, deletion |
| Member | Project | Work items, resources, updates, comments |
| Mentor | Project | Published progress and selected technical material; review and feedback |
| Client | Project | Published milestones, updates, deliverables, requests, and acceptance |
| Investor | Project | Published milestones, updates, risks, and selected KPIs |
| Viewer | Project | Read-only access to explicitly visible sections |

A user may have different roles in different projects. Workspace membership alone does not grant access to every project.

### Visibility

Publishable records support audiences: `internal`, `mentor`, `client`, `investor`, and `public-link`. Multiple external audiences may be selected. New content starts as `internal`. The API applies visibility rules to reads, search, exports, notifications, and activity feeds; hiding UI controls is not sufficient.

External URLs retain their provider's own permissions. Showing a Drive or GitHub link does not grant access to that service.

## L1 — Core product (releases 0.1 and 0.2)

L1 makes GoShipKit usable by a real small team and its mentor/client. Deep provider integration is not required.

### F01 — Account and authentication

- Email/password sign-in, sign-out, password reset, session management, and email verification.
- Recovery-safe password hashing and revocable sessions.
- Profile, avatar metadata, locale, time zone, and notification defaults.
- MFA is represented in the data model but authenticator-app enrollment is scheduled for L2.

Acceptance: a user can recover an account without an administrator; session revocation prevents subsequent authenticated requests.

### F02 — Workspace and multi-project overview

- Create, rename, archive, and switch workspaces.
- Invite and remove workspace members with owner/admin/member roles.
- Dashboard of accessible projects, assigned work, due-soon work, and recent updates.
- A user can belong to several workspaces and projects.

Acceptance: an owner can create a workspace, invite a member, create two projects, and the member sees only projects to which they were granted access.

### F03 — Project hub

- Name, key, description, thumbnail, status, start/target dates, health, and archive state.
- Simple navigation: Overview, Tasks, Resources, Updates, Members, Settings.
- Project owner and project-scoped membership.
- Soft deletion with a recovery window; destructive actions require explicit confirmation.

### F04 — Task management

- Work item types: task, bug, story, and subtask. Epic is available as a lightweight grouping type.
- Title, rich description, status, priority, due date, primary assignee, optional contributors, creator, and parent.
- Checklist/acceptance items, labels, comments, attachments as resource links, watchers, and mentions.
- List and Kanban views with drag-and-drop ordering.
- Default workflow: `To do → Doing → Review → Done`; Review may be skipped when project policy allows it.
- Basic blocker relationships; advanced dependency rules remain L2.

Acceptance: a member can create, assign, move, comment on, and complete a task; unauthorized stakeholders cannot enumerate internal tasks by guessing IDs.

`Done` records the team's internal completion decision; it is not external
acceptance. When a client, mentor, or another designated stakeholder must
confirm completion, the team submits the relevant result as a deliverable under
F14. This keeps internal workflow changes separate from auditable stakeholder
sign-off.

### F05 — Milestones and task-completion progress

- Milestone name, objective, owner, start/target dates, status, and linked tasks.
- Project and milestone task-completion values: completed eligible tasks / total eligible tasks.
- Overdue and blocked indicators; manually set project health with an explanation.
- Progress excludes archived/cancelled tasks and displays the calculation basis.

Acceptance: progress changes consistently when an eligible task enters or leaves a terminal completed status and never claims to represent actual effort.

### F06 — Project resources

- Store a name, URL, type, description, icon metadata, owner, and audience visibility.
- Initial types: source repository, document, design, diagram, demo, deployment, meeting, research, and other.
- Pin and order important links on the project overview.
- L1 stores links only; provider OAuth and file mirroring are out of scope.

### F07 — Progress updates

- Draft and publish weekly or milestone updates.
- Sections for summary, completed work, next work, blockers/risks, and linked tasks/resources/deliverables.
- Choose external audiences at publish time and preserve an edit history.
- Comments and mentor/client feedback on published updates.

Acceptance: a draft is invisible externally; publishing to `mentor` does not expose it to a client or investor.

### F08 — Stakeholder access and portals

- Project-scoped invitations for mentor, client, investor, and viewer presets.
- Dedicated dashboard derived from allowed sections and published records.
- Invite-only authenticated access is the L1 default.
- Client and mentor can submit feedback; internal notes remain hidden.
- Access can expire or be revoked. Invitation and access tokens are stored as hashes.

Portal presets:

- **Mentor:** progress, weekly reports, selected tasks/resources, review threads, and milestone feedback.
- **Client:** plain-language status, milestones, updates, demos/deliverables, and feedback.
- **Investor:** selected milestones, published risks, updates, and KPIs (richer KPI views arrive in L2).

### F09 — Collaboration and activity

- Flat comments in L1 with edit/delete history; threaded comments arrive in L2.
- `@mentions`, watchers, and in-app notifications.
- Project activity stream and append-only audit events for material changes.
- Notification preference controls and unread state.

### F10 — Search and filters

- Search accessible projects, tasks, resources, and updates by title/name.
- Task filters for project, status, priority, type, label, assignee, and due range.
- PostgreSQL full-text/trigram search with authorization applied before returning results.

### F11 — Self-hosting and administration

- Docker Compose deployment, environment-based configuration, health endpoint, structured logs, persistent PostgreSQL data, and documented backup/restore.
- English UI strings first; architecture is ready for Vietnamese localization.
- JSON and CSV project export for user data portability.
- No Redis, Kafka, Kubernetes, or external search service required.

## L2 — Team workflow and delivery (releases 0.3–1.x)

### F12 — Advanced boards and Scrum mode

- Custom statuses, ordered columns, WIP limits, and transition rules.
- Ranked product backlog, time-boxed sprints, sprint goals, Definition of Done, and increments.
- Story points, epic progress, velocity, and carry-over history.
- Scrum is opt-in per project; simple projects retain the default workflow.

### F13 — Dependencies, planning, and workload

- Blocking/blocked-by and related work-item links with cycle detection.
- Timeline and roadmap views, estimates, capacity, workload, and weighted milestone progress.
- Calendar feed and optional external calendar synchronization.
- Project health report based on overdue work, blocked milestones, and declared risks.

### F14 — Deliverables and client acceptance

- Versioned deliverables linked to milestones and resources.
- Workflow: draft → submitted → approved or changes requested → revised → approved.
- Named acceptance criteria, decision comments, decision timestamp, and immutable decision history.
- Client change requests with scope/priority decision and optional links to resulting tasks.
- Approval applies to a specific deliverable revision and may be made only by a
  project-scoped member with the acceptance capability. Client and mentor are
  useful presets, not automatic approvers; the project owner designates who can
  sign off.
- A finding before approval becomes `changes_requested` and leads to a new
  revision. A finding after approval does not rewrite the accepted revision: it
  becomes a linked bug when the accepted criteria are no longer met, or a linked
  task/change request when it is new or changed scope.

Acceptance: only an authorized approver can decide; the actor, timestamp,
revision, criteria, and decision remain auditable; internal comments and
unpublished revisions never appear in the stakeholder portal.

### F15 — GitHub integration

- Connect repositories through a GitHub App or appropriately scoped OAuth installation.
- Synchronize repository, branch, commit, pull request, review, and check-run metadata.
- Link tasks manually and by recognized task key in branch/PR text.
- Signed, idempotent webhook ingestion with retries, dead-letter visibility, and reconciliation.
- GoShipKit never hosts repositories, renders a full code review interface, or runs CI.

GitLab, Gitea, and Forgejo adapters are L3 unless adoption data moves one forward.

### F16 — Notifications and email

- In-app and email notifications for assignment, mention, deadline, feedback, review, and acceptance.
- Per-event/channel preferences, subscriptions, digest mode, and quiet hours.
- Delivery attempts and failure state for administrators without exposing message secrets.

### F17 — Reports, analytics, and exports

- Cycle time, lead time, throughput, review time, completion trend, and workload.
- Published investor KPIs with source, period, value, target, and commentary.
- Scheduled reports and exports to PDF, Markdown, JSON, and CSV.
- Metrics explain their formula and avoid ranking people by commits, online time, or raw task count.

### F18 — Documents and diagrams

- Versioned Markdown documents, document tree, templates, and links to project entities.
- Safe Mermaid rendering and embedded links for Excalidraw/diagrams.net.
- Document/diagram audience visibility and change history.
- Collaborative real-time editing is deferred until usage justifies its complexity.

### F19 — API, webhooks, and service accounts

- Versioned REST API documented with OpenAPI.
- Scoped service-account/API keys stored as hashes with expiry and last-used metadata.
- Signed outbound webhooks, event subscriptions, delivery retries, and replay controls.
- Rate limits and audit records for credential administration.

### F20 — Security and customization

- Authenticator-app two-factor authentication with one-time recovery codes.
- Custom access groups/capabilities where presets are insufficient.
- Workspace logo, colors, portal identity, and invitation branding.
- Time-limited public share links only for explicitly low-sensitivity published content.
- Basic retention settings and security-event review.

### F21 — Testing and acceptance management

- Plain-language test steps on work items.
- Reusable test cases, suites, executions/cycles, results, and evidence links.
- Link defects to failed runs and deliverables to acceptance runs.
- This is lightweight QA coordination, not automated test execution.

### F22 — Intake and templates

- Project templates for capstone, freelance, research, and lightweight product teams.
- CSV task import/export with validation and preview.
- Generic intake inbox and webhook/email/API adapters.
- Sentry intake may be the first adapter; SupportLayer is not a committed dependency and requires demand validation.

## L3 — Advanced and optional

### F23 — Multi-provider integrations

GitLab, Gitea, and Forgejo metadata adapters; provider-neutral task/PR links; deployment and release metadata; integration health and reconciliation tools.

### F24 — Automation

Event/condition/action rules, approval gates, and suggestions such as “PR merged—mark linked task ready for review.” Mutating automations are auditable, retry-safe, and can require human confirmation.

### F25 — Engineering traceability and intelligence

- Generic links among requirements, tasks, documents, diagrams, pull requests, tests, deliverables, and releases.
- Coverage gaps, impact suggestions, stale-document signals, PR bottlenecks, and delivery risks.
- PostgreSQL entity links first; no graph database until query/load evidence requires one.

### F26 — AI assistance

- Grounded weekly summaries, release-note drafts, project Q&A, and risk suggestions with citations to authorized internal records.
- AI suggestions never bypass permissions and require confirmation before important mutations.
- Workspace administrators control enablement, provider, retention, and eligible data.

### F27 — Platform expansion

- Extension SDK and plugin registry after the public API stabilizes.
- Multi-project investor portfolio view.
- Optional OIDC/SSO, fine-grained policy controls, audit retention, and S3-compatible object storage.
- Offline desktop cache and conflict-aware synchronization only after a validated offline need.

## Evaluation of referenced ProjectLayer features

| Referenced feature | Decision | GoShipKit phase | Rationale |
|---|---|---:|---|
| Kanban boards | Keep | L1 | Core simple task view; real-time multi-user updates can mature later. |
| Scrum mode | Keep as optional | L2 | Valuable to software teams but too complex as the default. |
| Epics and user stories | Keep lightweight | L1/L2 | Basic hierarchy in L1; points and strict epic completion rules in L2. |
| Rich task management | Split | L1/L2 | Assignment, priority, subtasks, blockers, watchers, mentions in L1; time logs/points/import depth in L2. |
| Sentry and SupportLayer intake | Defer/validate | L2+ | Generic intake first; do not bind the roadmap to a niche provider prematurely. |
| Client portal | Strongly keep | L1 | A core differentiator for freelance and small project teams. |
| Testing and acceptance | Keep | L2 | Client acceptance is high value; full QA structures should not block MVP. |
| Milestones and releases | Split | L1/L2 | Milestones in L1; release and delivery lifecycle in L2. |
| Team collaboration | Keep | L1/L2 | Comments, mentions, roles in L1; custom access groups and threads in L2. |
| Custom labels | Keep | L1 | Low complexity and high organization value. |
| API and webhooks | Keep | L2 | Stabilize the domain/API before promising a public integration surface. |
| Audit trail | Keep | L1 | Needed for trust, stakeholder decisions, and security investigations. |
| Notifications | Split | L1/L2 | In-app in L1; configurable email/digests in L2. |
| Two-factor sign-in | Keep | L2 | Important before production maturity but not a foundation blocker. |
| Reports and analytics | Keep | L2 | Must use explainable team metrics and avoid surveillance metrics. |
| Search and filters | Keep | L1 | Essential as soon as several projects exist. |
| Branding | Keep | L2 | Important for client-facing teams after the portal workflow proves useful. |

## Explicitly out of scope

- Hosting Git repositories or implementing Git.
- Source-code editor, IDE, or remote developer environment in the initial roadmap.
- CI/CD runner, container registry, or deployment engine.
- Cloud-drive replacement or automatic access grants to external links.
- Employee surveillance, commit-count performance scores, or online-time tracking.
- Microservices, Kafka, Kubernetes, Elasticsearch, or a graph database for the MVP.
- Autonomous agents that change code, project data, or workflows without confirmation.

## Release slices

### 0.1 — Project Hub

Authentication, workspaces, projects, members, task list/Kanban, labels, milestones, resource links, explainable task completion, search, and Docker Compose.

### 0.2 — Collaboration and Stakeholders

Progress updates, portal invitations, visibility policies, mentor/client views, feedback, notifications, and activity/audit history.

### 0.3 — Developer Integration

GitHub metadata, PR/task links, diagrams preview, exports, and stronger notification delivery.

### 1.0 — Public source-available release

Stable API, onboarding/templates, backup/restore verification, import/export, deployment documentation, MFA, security hardening, and accessibility/localization review.

## Non-functional requirements

| ID | Requirement |
|---|---|
| NFR-01 | Self-host on Linux with Docker Compose and persistent PostgreSQL data. |
| NFR-02 | Support 2–10 active users per workspace initially without special infrastructure. |
| NFR-03 | Responsive web UI for laptop, tablet, and mobile; keyboard-accessible core flows. |
| NFR-04 | Enforce tenant, project, capability, and visibility checks at every API boundary. |
| NFR-05 | Document and verify backup, restore, schema migration, and disaster recovery. |
| NFR-06 | Provide health/readiness endpoints, structured logs, request IDs, and auditable changes. |
| NFR-07 | Export user-owned project data in documented JSON/CSV formats. |
| NFR-08 | Work fully without GitHub, Drive, or any optional integration. |
| NFR-09 | English UI initially; externalized strings and locale-aware dates for Vietnamese support. |
| NFR-10 | Hash passwords/tokens and encrypt recoverable OAuth/provider secrets; never log secrets. |
| NFR-11 | Webhook consumers are signature-verified, idempotent, retry-safe, and reconcilable. |
| NFR-12 | Published progress calculations expose their source and formula. |
| NFR-13 | Meet WCAG 2.2 AA for core web workflows by 1.0. |
| NFR-14 | Use UTC timestamps in storage and render dates in the viewer's configured time zone. |

## MVP success criteria

- A team can replace scattered spreadsheets for day-to-day task and project-status tracking.
- A mentor or client can understand current progress and leave feedback without opening GitHub.
- Private internal data remains inaccessible through direct IDs, search, export, notifications, and portal routes.
- A fresh self-host install survives restart, can be backed up/restored, and requires no optional provider account.
- A new team can create its first project, add resource links, and publish a progress update without learning Scrum terminology.
