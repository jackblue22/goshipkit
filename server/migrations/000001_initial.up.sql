-- GoShipKit initial PostgreSQL schema
-- Target: PostgreSQL 18 (syntax remains compatible with PostgreSQL 15+).
-- This file models the full L1-L3 product roadmap. Features are enabled by the
-- application release plan; table presence does not imply a shipped feature.

BEGIN;

CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS goshipkit;
SET search_path TO goshipkit, public;

CREATE FUNCTION set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Identity and authentication -------------------------------------------------

CREATE TABLE users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email citext NOT NULL UNIQUE,
    display_name text NOT NULL CHECK (length(btrim(display_name)) BETWEEN 1 AND 120),
    avatar_url text,
    locale text NOT NULL DEFAULT 'en',
    time_zone text NOT NULL DEFAULT 'UTC',
    email_verified_at timestamptz,
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('invited', 'active', 'suspended', 'deleted')),
    last_seen_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz
);

CREATE TABLE user_passwords (
    user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    password_hash text NOT NULL,
    password_changed_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE auth_identities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider text NOT NULL,
    subject text NOT NULL,
    email_at_provider citext,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (provider, subject)
);

CREATE TABLE auth_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash bytea NOT NULL UNIQUE,
    user_agent text,
    ip_address inet,
    expires_at timestamptz NOT NULL,
    last_used_at timestamptz NOT NULL DEFAULT now(),
    revoked_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (expires_at > created_at)
);

CREATE TABLE verification_tokens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES users(id) ON DELETE CASCADE,
    email citext NOT NULL,
    purpose text NOT NULL CHECK (purpose IN ('verify_email', 'reset_password', 'accept_invitation')),
    token_hash bytea NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    consumed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE mfa_methods (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    method text NOT NULL CHECK (method IN ('totp')),
    label text NOT NULL,
    secret_ciphertext bytea NOT NULL,
    verified_at timestamptz,
    last_used_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE mfa_recovery_codes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash bytea NOT NULL,
    used_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, code_hash)
);

-- Workspaces, projects, and access --------------------------------------------

CREATE TABLE workspaces (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9][a-z0-9-]{1,62}$'),
    name text NOT NULL CHECK (length(btrim(name)) BETWEEN 1 AND 120),
    description text,
    owner_user_id uuid NOT NULL REFERENCES users(id),
    logo_url text,
    brand_color varchar(9),
    settings jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(settings) = 'object'),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    archived_at timestamptz
);

CREATE TABLE workspace_members (
    workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role text NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
    joined_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (workspace_id, user_id)
);

CREATE TABLE workspace_invitations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    email citext NOT NULL,
    role text NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    token_hash bytea NOT NULL UNIQUE,
    invited_by uuid NOT NULL REFERENCES users(id),
    expires_at timestamptz NOT NULL,
    accepted_by uuid REFERENCES users(id),
    accepted_at timestamptz,
    revoked_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (expires_at > created_at)
);

CREATE TABLE projects (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    project_key varchar(10) NOT NULL CHECK (project_key ~ '^[A-Z][A-Z0-9]{1,9}$'),
    name text NOT NULL CHECK (length(btrim(name)) BETWEEN 1 AND 160),
    description text,
    thumbnail_url text,
    status text NOT NULL DEFAULT 'planning' CHECK (status IN ('planning', 'active', 'on_hold', 'completed', 'cancelled', 'archived')),
    health text CHECK (health IN ('on_track', 'at_risk', 'off_track')),
    health_note text,
    starts_on date,
    target_date date,
    owner_user_id uuid NOT NULL REFERENCES users(id),
    default_visibility text NOT NULL DEFAULT 'internal' CHECK (default_visibility IN ('internal', 'members')),
    settings jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(settings) = 'object'),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    archived_at timestamptz,
    deleted_at timestamptz,
    UNIQUE (workspace_id, project_key),
    CHECK (target_date IS NULL OR starts_on IS NULL OR target_date >= starts_on)
);

CREATE TABLE project_members (
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role text NOT NULL CHECK (role IN ('owner', 'member', 'mentor', 'client', 'investor', 'viewer')),
    permissions jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(permissions) = 'object'),
    invited_by uuid REFERENCES users(id),
    joined_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz,
    revoked_at timestamptz,
    PRIMARY KEY (project_id, user_id)
);

CREATE TABLE project_invitations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    email citext NOT NULL,
    role text NOT NULL CHECK (role IN ('member', 'mentor', 'client', 'investor', 'viewer')),
    permissions jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(permissions) = 'object'),
    token_hash bytea NOT NULL UNIQUE,
    invited_by uuid NOT NULL REFERENCES users(id),
    expires_at timestamptz NOT NULL,
    accepted_by uuid REFERENCES users(id),
    accepted_at timestamptz,
    revoked_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (expires_at > created_at)
);

CREATE TABLE access_groups (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    capabilities text[] NOT NULL DEFAULT '{}',
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (project_id, name)
);

CREATE TABLE access_group_members (
    access_group_id uuid NOT NULL REFERENCES access_groups(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    added_by uuid NOT NULL REFERENCES users(id),
    added_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (access_group_id, user_id)
);

CREATE TABLE share_links (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    label text NOT NULL,
    token_hash bytea NOT NULL UNIQUE,
    allowed_sections text[] NOT NULL DEFAULT '{}',
    created_by uuid NOT NULL REFERENCES users(id),
    expires_at timestamptz NOT NULL,
    revoked_at timestamptz,
    last_accessed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (expires_at > created_at)
);

-- Planning and work management ------------------------------------------------

CREATE TABLE workflows (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name text NOT NULL,
    mode text NOT NULL DEFAULT 'kanban' CHECK (mode IN ('simple', 'kanban', 'scrum')),
    is_default boolean NOT NULL DEFAULT false,
    definition_of_done text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (project_id, name)
);

CREATE UNIQUE INDEX workflows_one_default_per_project ON workflows(project_id) WHERE is_default;

CREATE TABLE workflow_statuses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id uuid NOT NULL REFERENCES workflows(id) ON DELETE CASCADE,
    name text NOT NULL,
    category text NOT NULL CHECK (category IN ('backlog', 'todo', 'in_progress', 'review', 'done', 'cancelled')),
    color varchar(9),
    position integer NOT NULL CHECK (position >= 0),
    wip_limit integer CHECK (wip_limit > 0),
    is_terminal boolean NOT NULL DEFAULT false,
    UNIQUE (workflow_id, name),
    UNIQUE (workflow_id, position)
);

CREATE TABLE workflow_transitions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id uuid NOT NULL REFERENCES workflows(id) ON DELETE CASCADE,
    from_status_id uuid NOT NULL REFERENCES workflow_statuses(id) ON DELETE CASCADE,
    to_status_id uuid NOT NULL REFERENCES workflow_statuses(id) ON DELETE CASCADE,
    requires_definition_of_done boolean NOT NULL DEFAULT false,
    allowed_roles text[] NOT NULL DEFAULT '{}',
    UNIQUE (workflow_id, from_status_id, to_status_id),
    CHECK (from_status_id <> to_status_id)
);

CREATE TABLE milestones (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    owner_user_id uuid REFERENCES users(id),
    status text NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'completed', 'cancelled')),
    starts_on date,
    target_date date,
    completed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (target_date IS NULL OR starts_on IS NULL OR target_date >= starts_on)
);

CREATE TABLE sprints (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name text NOT NULL,
    goal text,
    status text NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'completed', 'cancelled')),
    starts_at timestamptz,
    ends_at timestamptz,
    completed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at)
);

CREATE TABLE work_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    item_number bigint GENERATED BY DEFAULT AS IDENTITY,
    parent_id uuid REFERENCES work_items(id) ON DELETE SET NULL,
    epic_id uuid REFERENCES work_items(id) ON DELETE SET NULL,
    milestone_id uuid REFERENCES milestones(id) ON DELETE SET NULL,
    sprint_id uuid REFERENCES sprints(id) ON DELETE SET NULL,
    status_id uuid NOT NULL REFERENCES workflow_statuses(id),
    type text NOT NULL DEFAULT 'task' CHECK (type IN ('epic', 'story', 'task', 'bug', 'subtask')),
    title text NOT NULL CHECK (length(btrim(title)) BETWEEN 1 AND 300),
    description text,
    priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('none', 'low', 'medium', 'high', 'urgent')),
    reporter_user_id uuid NOT NULL REFERENCES users(id),
    assignee_user_id uuid REFERENCES users(id),
    estimate_points numeric(8,2) CHECK (estimate_points >= 0),
    due_at timestamptz,
    rank numeric(30,15) NOT NULL DEFAULT 0,
    completed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    archived_at timestamptz,
    UNIQUE (project_id, item_number),
    CHECK (parent_id IS NULL OR parent_id <> id),
    CHECK (epic_id IS NULL OR epic_id <> id)
);

CREATE TABLE work_item_contributors (
    work_item_id uuid NOT NULL REFERENCES work_items(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    added_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (work_item_id, user_id)
);

CREATE TABLE work_item_watchers (
    work_item_id uuid NOT NULL REFERENCES work_items(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (work_item_id, user_id)
);

CREATE TABLE labels (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name citext NOT NULL,
    color varchar(9) NOT NULL,
    description text,
    UNIQUE (project_id, name)
);

CREATE TABLE work_item_labels (
    work_item_id uuid NOT NULL REFERENCES work_items(id) ON DELETE CASCADE,
    label_id uuid NOT NULL REFERENCES labels(id) ON DELETE CASCADE,
    PRIMARY KEY (work_item_id, label_id)
);

CREATE TABLE checklist_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    work_item_id uuid NOT NULL REFERENCES work_items(id) ON DELETE CASCADE,
    body text NOT NULL,
    position integer NOT NULL DEFAULT 0 CHECK (position >= 0),
    is_completed boolean NOT NULL DEFAULT false,
    completed_by uuid REFERENCES users(id),
    completed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE work_item_relations (
    source_id uuid NOT NULL REFERENCES work_items(id) ON DELETE CASCADE,
    target_id uuid NOT NULL REFERENCES work_items(id) ON DELETE CASCADE,
    relation text NOT NULL CHECK (relation IN ('blocks', 'relates_to', 'duplicates')),
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (source_id, target_id, relation),
    CHECK (source_id <> target_id)
);

CREATE TABLE time_entries (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    work_item_id uuid NOT NULL REFERENCES work_items(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id),
    minutes integer NOT NULL CHECK (minutes > 0),
    note text,
    logged_on date NOT NULL DEFAULT CURRENT_DATE,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Knowledge, updates, portals, and acceptance --------------------------------

CREATE TABLE project_resources (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name text NOT NULL,
    url text NOT NULL CHECK (url ~ '^https?://'),
    resource_type text NOT NULL CHECK (resource_type IN ('repository', 'document', 'design', 'diagram', 'demo', 'deployment', 'meeting', 'research', 'other')),
    description text,
    icon_url text,
    created_by uuid NOT NULL REFERENCES users(id),
    position integer NOT NULL DEFAULT 0 CHECK (position >= 0),
    is_pinned boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    archived_at timestamptz
);

CREATE TABLE project_updates (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    milestone_id uuid REFERENCES milestones(id) ON DELETE SET NULL,
    update_type text NOT NULL DEFAULT 'weekly' CHECK (update_type IN ('weekly', 'milestone', 'announcement', 'risk')),
    title text NOT NULL,
    summary text NOT NULL,
    completed_work text,
    next_work text,
    blockers text,
    status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    author_user_id uuid NOT NULL REFERENCES users(id),
    published_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK ((status = 'published') = (published_at IS NOT NULL) OR status = 'archived')
);

CREATE TABLE project_update_revisions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    update_id uuid NOT NULL REFERENCES project_updates(id) ON DELETE CASCADE,
    revision integer NOT NULL CHECK (revision > 0),
    snapshot jsonb NOT NULL CHECK (jsonb_typeof(snapshot) = 'object'),
    edited_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (update_id, revision)
);

CREATE TABLE documents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    parent_id uuid REFERENCES documents(id) ON DELETE SET NULL,
    title text NOT NULL,
    slug citext NOT NULL,
    current_revision integer NOT NULL DEFAULT 0 CHECK (current_revision >= 0),
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    archived_at timestamptz,
    UNIQUE (project_id, slug),
    CHECK (parent_id IS NULL OR parent_id <> id)
);

CREATE TABLE document_revisions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    revision integer NOT NULL CHECK (revision > 0),
    body_markdown text NOT NULL,
    change_summary text,
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (document_id, revision)
);

CREATE TABLE diagrams (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name text NOT NULL,
    format text NOT NULL CHECK (format IN ('mermaid', 'excalidraw_link', 'diagrams_net_link', 'external_link')),
    source text NOT NULL,
    revision integer NOT NULL DEFAULT 1 CHECK (revision > 0),
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE deliverables (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    milestone_id uuid REFERENCES milestones(id) ON DELETE SET NULL,
    title text NOT NULL,
    description text,
    status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'changes_requested', 'approved', 'withdrawn')),
    owner_user_id uuid REFERENCES users(id),
    due_at timestamptz,
    current_revision integer NOT NULL DEFAULT 0 CHECK (current_revision >= 0),
    submitted_at timestamptz,
    approved_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE deliverable_revisions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    deliverable_id uuid NOT NULL REFERENCES deliverables(id) ON DELETE CASCADE,
    revision integer NOT NULL CHECK (revision > 0),
    description text,
    submitted_by uuid NOT NULL REFERENCES users(id),
    submitted_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (deliverable_id, revision)
);

CREATE TABLE deliverable_resources (
    deliverable_revision_id uuid NOT NULL REFERENCES deliverable_revisions(id) ON DELETE CASCADE,
    resource_id uuid NOT NULL REFERENCES project_resources(id) ON DELETE CASCADE,
    PRIMARY KEY (deliverable_revision_id, resource_id)
);

CREATE TABLE acceptance_criteria (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    deliverable_id uuid NOT NULL REFERENCES deliverables(id) ON DELETE CASCADE,
    body text NOT NULL,
    position integer NOT NULL DEFAULT 0 CHECK (position >= 0),
    is_met boolean NOT NULL DEFAULT false,
    verified_by uuid REFERENCES users(id),
    verified_at timestamptz
);

CREATE TABLE deliverable_reviews (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    deliverable_revision_id uuid NOT NULL REFERENCES deliverable_revisions(id) ON DELETE CASCADE,
    reviewer_user_id uuid NOT NULL REFERENCES users(id),
    decision text NOT NULL CHECK (decision IN ('approved', 'changes_requested')),
    comment text,
    decided_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (deliverable_revision_id, reviewer_user_id)
);

CREATE TABLE change_requests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    requested_by uuid NOT NULL REFERENCES users(id),
    title text NOT NULL,
    description text NOT NULL,
    priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status text NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'accepted', 'declined', 'in_progress', 'completed', 'cancelled')),
    decision_note text,
    decided_by uuid REFERENCES users(id),
    decided_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE project_feedback (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    author_user_id uuid NOT NULL REFERENCES users(id),
    milestone_id uuid REFERENCES milestones(id) ON DELETE SET NULL,
    update_id uuid REFERENCES project_updates(id) ON DELETE SET NULL,
    title text,
    body text NOT NULL,
    feedback_type text NOT NULL DEFAULT 'comment' CHECK (feedback_type IN ('comment', 'review', 'request_change', 'question')),
    status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'acknowledged', 'resolved', 'dismissed')),
    resolved_by uuid REFERENCES users(id),
    resolved_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE comments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    parent_id uuid REFERENCES comments(id) ON DELETE CASCADE,
    work_item_id uuid REFERENCES work_items(id) ON DELETE CASCADE,
    update_id uuid REFERENCES project_updates(id) ON DELETE CASCADE,
    feedback_id uuid REFERENCES project_feedback(id) ON DELETE CASCADE,
    change_request_id uuid REFERENCES change_requests(id) ON DELETE CASCADE,
    author_user_id uuid NOT NULL REFERENCES users(id),
    body text NOT NULL,
    is_internal boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz,
    CHECK (num_nonnulls(work_item_id, update_id, feedback_id, change_request_id) = 1),
    CHECK (parent_id IS NULL OR parent_id <> id)
);

CREATE TABLE entity_visibility (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    entity_type text NOT NULL CHECK (entity_type IN ('resource', 'update', 'milestone', 'work_item', 'document', 'diagram', 'deliverable', 'risk', 'kpi')),
    entity_id uuid NOT NULL,
    audience text NOT NULL CHECK (audience IN ('mentor', 'client', 'investor', 'viewer', 'public_link')),
    granted_by uuid NOT NULL REFERENCES users(id),
    granted_at timestamptz NOT NULL DEFAULT now(),
    revoked_at timestamptz,
    UNIQUE NULLS NOT DISTINCT (project_id, entity_type, entity_id, audience, revoked_at)
);

CREATE TABLE entity_links (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    source_type text NOT NULL,
    source_id uuid NOT NULL,
    target_type text NOT NULL,
    target_id uuid NOT NULL,
    relation text NOT NULL DEFAULT 'relates_to',
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (project_id, source_type, source_id, target_type, target_id, relation),
    CHECK (source_type <> target_type OR source_id <> target_id)
);

CREATE TABLE risks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    probability smallint CHECK (probability BETWEEN 1 AND 5),
    impact smallint CHECK (impact BETWEEN 1 AND 5),
    status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'mitigating', 'accepted', 'closed')),
    mitigation text,
    owner_user_id uuid REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE project_kpis (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    unit text NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    value numeric NOT NULL,
    target numeric,
    source_note text NOT NULL,
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (period_end >= period_start)
);

-- Integrations and developer metadata ----------------------------------------

CREATE TABLE integration_connections (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    provider text NOT NULL CHECK (provider IN ('github', 'gitlab', 'gitea', 'forgejo', 'sentry', 'calendar', 'email', 'oidc', 'custom')),
    external_account_id text,
    display_name text NOT NULL,
    credentials_ciphertext bytea,
    webhook_secret_ciphertext bytea,
    scopes text[] NOT NULL DEFAULT '{}',
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'degraded', 'revoked', 'disabled')),
    last_synced_at timestamptz,
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE NULLS NOT DISTINCT (workspace_id, provider, external_account_id)
);

CREATE TABLE repositories (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    connection_id uuid NOT NULL REFERENCES integration_connections(id) ON DELETE CASCADE,
    provider text NOT NULL,
    external_id text NOT NULL,
    owner_name text NOT NULL,
    name text NOT NULL,
    web_url text NOT NULL,
    default_branch text,
    is_private boolean NOT NULL DEFAULT true,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    last_synced_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (connection_id, external_id)
);

CREATE TABLE git_branches (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_id uuid NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    external_id text,
    name text NOT NULL,
    head_sha text,
    web_url text,
    is_default boolean NOT NULL DEFAULT false,
    last_seen_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (repository_id, name)
);

CREATE TABLE git_commits (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_id uuid NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    sha text NOT NULL,
    message text NOT NULL,
    author_name text,
    author_email text,
    authored_at timestamptz,
    web_url text,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    UNIQUE (repository_id, sha)
);

CREATE TABLE pull_requests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_id uuid NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    external_id text NOT NULL,
    number bigint NOT NULL,
    title text NOT NULL,
    body text,
    state text NOT NULL CHECK (state IN ('open', 'closed', 'merged', 'draft')),
    author_external_id text,
    head_ref text,
    base_ref text,
    web_url text NOT NULL,
    opened_at timestamptz,
    merged_at timestamptz,
    closed_at timestamptz,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    last_synced_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (repository_id, external_id),
    UNIQUE (repository_id, number)
);

CREATE TABLE pull_request_reviews (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    pull_request_id uuid NOT NULL REFERENCES pull_requests(id) ON DELETE CASCADE,
    external_id text NOT NULL,
    reviewer_external_id text,
    state text NOT NULL,
    submitted_at timestamptz,
    web_url text,
    UNIQUE (pull_request_id, external_id)
);

CREATE TABLE ci_check_runs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_id uuid NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    pull_request_id uuid REFERENCES pull_requests(id) ON DELETE CASCADE,
    external_id text NOT NULL,
    name text NOT NULL,
    status text NOT NULL,
    conclusion text,
    web_url text,
    started_at timestamptz,
    completed_at timestamptz,
    UNIQUE (repository_id, external_id)
);

CREATE TABLE releases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    repository_id uuid REFERENCES repositories(id) ON DELETE SET NULL,
    milestone_id uuid REFERENCES milestones(id) ON DELETE SET NULL,
    external_id text,
    name text NOT NULL,
    tag_name text,
    status text NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'published', 'withdrawn')),
    notes text,
    web_url text,
    target_date date,
    published_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE NULLS NOT DISTINCT (repository_id, external_id)
);

CREATE TABLE inbound_webhook_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    connection_id uuid NOT NULL REFERENCES integration_connections(id) ON DELETE CASCADE,
    provider_event_id text NOT NULL,
    event_type text NOT NULL,
    signature_valid boolean NOT NULL,
    payload jsonb NOT NULL,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'processed', 'failed', 'dead_letter')),
    attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    next_attempt_at timestamptz,
    processed_at timestamptz,
    error_message text,
    received_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (connection_id, provider_event_id)
);

-- QA and acceptance -----------------------------------------------------------

CREATE TABLE test_suites (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE test_cases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    suite_id uuid REFERENCES test_suites(id) ON DELETE SET NULL,
    work_item_id uuid REFERENCES work_items(id) ON DELETE SET NULL,
    title text NOT NULL,
    preconditions text,
    expected_result text NOT NULL,
    priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE test_case_steps (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    test_case_id uuid NOT NULL REFERENCES test_cases(id) ON DELETE CASCADE,
    position integer NOT NULL CHECK (position >= 0),
    instruction text NOT NULL,
    expected_result text,
    UNIQUE (test_case_id, position)
);

CREATE TABLE test_runs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name text NOT NULL,
    release_id uuid REFERENCES releases(id) ON DELETE SET NULL,
    deliverable_revision_id uuid REFERENCES deliverable_revisions(id) ON DELETE SET NULL,
    status text NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'running', 'completed', 'cancelled')),
    started_at timestamptz,
    completed_at timestamptz,
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE test_results (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    test_run_id uuid NOT NULL REFERENCES test_runs(id) ON DELETE CASCADE,
    test_case_id uuid NOT NULL REFERENCES test_cases(id),
    executor_user_id uuid REFERENCES users(id),
    result text NOT NULL CHECK (result IN ('untested', 'passed', 'failed', 'blocked', 'skipped')),
    notes text,
    executed_at timestamptz,
    UNIQUE (test_run_id, test_case_id)
);

-- Notifications, APIs, reports, intake, and automation ------------------------

CREATE TABLE notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workspace_id uuid REFERENCES workspaces(id) ON DELETE CASCADE,
    project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
    event_type text NOT NULL,
    title text NOT NULL,
    body text,
    action_url text,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    read_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE notification_preferences (
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_type text NOT NULL,
    in_app_enabled boolean NOT NULL DEFAULT true,
    email_enabled boolean NOT NULL DEFAULT true,
    digest text NOT NULL DEFAULT 'immediate' CHECK (digest IN ('immediate', 'daily', 'weekly', 'never')),
    PRIMARY KEY (user_id, event_type)
);

CREATE TABLE notification_deliveries (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id uuid NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    channel text NOT NULL CHECK (channel IN ('in_app', 'email', 'push')),
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'cancelled')),
    attempts integer NOT NULL DEFAULT 0,
    last_error text,
    sent_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (notification_id, channel)
);

CREATE TABLE service_accounts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    disabled_at timestamptz,
    UNIQUE (workspace_id, name)
);

CREATE TABLE api_keys (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    service_account_id uuid NOT NULL REFERENCES service_accounts(id) ON DELETE CASCADE,
    key_prefix varchar(16) NOT NULL,
    key_hash bytea NOT NULL UNIQUE,
    scopes text[] NOT NULL DEFAULT '{}',
    expires_at timestamptz,
    last_used_at timestamptz,
    revoked_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE outbound_webhooks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
    name text NOT NULL,
    target_url text NOT NULL CHECK (target_url ~ '^https://'),
    secret_ciphertext bytea NOT NULL,
    event_types text[] NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE outbound_webhook_deliveries (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    webhook_id uuid NOT NULL REFERENCES outbound_webhooks(id) ON DELETE CASCADE,
    event_id uuid NOT NULL,
    payload jsonb NOT NULL,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'delivered', 'failed', 'dead_letter')),
    attempts integer NOT NULL DEFAULT 0,
    response_status integer,
    next_attempt_at timestamptz,
    delivered_at timestamptz,
    last_error text,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (webhook_id, event_id)
);

CREATE TABLE intake_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    connection_id uuid REFERENCES integration_connections(id) ON DELETE SET NULL,
    source text NOT NULL,
    external_id text,
    title text NOT NULL,
    description text,
    status text NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'triaged', 'converted', 'dismissed')),
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    converted_work_item_id uuid REFERENCES work_items(id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE NULLS NOT DISTINCT (connection_id, external_id)
);

CREATE TABLE report_definitions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name text NOT NULL,
    format text NOT NULL CHECK (format IN ('pdf', 'markdown', 'json', 'csv')),
    schedule_cron text,
    config jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_by uuid NOT NULL REFERENCES users(id),
    last_run_at timestamptz,
    next_run_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE automation_rules (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name text NOT NULL,
    event_type text NOT NULL,
    conditions jsonb NOT NULL DEFAULT '[]'::jsonb,
    actions jsonb NOT NULL DEFAULT '[]'::jsonb,
    requires_confirmation boolean NOT NULL DEFAULT false,
    is_enabled boolean NOT NULL DEFAULT false,
    created_by uuid NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (jsonb_typeof(conditions) = 'array'),
    CHECK (jsonb_typeof(actions) = 'array')
);

CREATE TABLE background_jobs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    queue text NOT NULL DEFAULT 'default',
    job_type text NOT NULL,
    payload jsonb NOT NULL,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed', 'dead_letter')),
    priority smallint NOT NULL DEFAULT 0,
    attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    max_attempts integer NOT NULL DEFAULT 10 CHECK (max_attempts > 0),
    run_after timestamptz NOT NULL DEFAULT now(),
    locked_at timestamptz,
    locked_by text,
    completed_at timestamptz,
    last_error text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Audit and observability ------------------------------------------------------

CREATE TABLE activity_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
    actor_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    event_type text NOT NULL,
    entity_type text NOT NULL,
    entity_id uuid,
    summary text NOT NULL,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE audit_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid REFERENCES workspaces(id) ON DELETE SET NULL,
    project_id uuid REFERENCES projects(id) ON DELETE SET NULL,
    actor_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    actor_type text NOT NULL DEFAULT 'user' CHECK (actor_type IN ('user', 'service_account', 'system')),
    action text NOT NULL,
    target_type text NOT NULL,
    target_id uuid,
    request_id text,
    ip_address inet,
    user_agent text,
    before_data jsonb,
    after_data jsonb,
    occurred_at timestamptz NOT NULL DEFAULT now()
);

-- Search and performance indexes ---------------------------------------------

CREATE INDEX users_status_idx ON users(status) WHERE deleted_at IS NULL;
CREATE INDEX auth_sessions_active_idx ON auth_sessions(user_id, expires_at) WHERE revoked_at IS NULL;
CREATE INDEX workspace_members_user_idx ON workspace_members(user_id);
CREATE INDEX projects_workspace_status_idx ON projects(workspace_id, status) WHERE deleted_at IS NULL;
CREATE INDEX project_members_user_idx ON project_members(user_id, project_id) WHERE revoked_at IS NULL;
CREATE INDEX work_items_project_status_rank_idx ON work_items(project_id, status_id, rank) WHERE archived_at IS NULL;
CREATE INDEX work_items_assignee_due_idx ON work_items(assignee_user_id, due_at) WHERE completed_at IS NULL AND archived_at IS NULL;
CREATE INDEX work_items_search_idx ON work_items USING gin (to_tsvector('simple', title || ' ' || coalesce(description, '')));
CREATE INDEX resources_project_position_idx ON project_resources(project_id, is_pinned DESC, position) WHERE archived_at IS NULL;
CREATE INDEX resources_search_idx ON project_resources USING gin (to_tsvector('simple', name || ' ' || coalesce(description, '')));
CREATE INDEX updates_project_published_idx ON project_updates(project_id, published_at DESC) WHERE status = 'published';
CREATE INDEX documents_search_idx ON documents USING gin (to_tsvector('simple', title));
CREATE INDEX comments_work_item_idx ON comments(work_item_id, created_at) WHERE deleted_at IS NULL;
CREATE INDEX entity_visibility_lookup_idx ON entity_visibility(project_id, entity_type, entity_id, audience) WHERE revoked_at IS NULL;
CREATE INDEX entity_links_source_idx ON entity_links(project_id, source_type, source_id);
CREATE INDEX entity_links_target_idx ON entity_links(project_id, target_type, target_id);
CREATE INDEX notifications_unread_idx ON notifications(user_id, created_at DESC) WHERE read_at IS NULL;
CREATE INDEX activity_project_time_idx ON activity_events(project_id, occurred_at DESC);
CREATE INDEX audit_workspace_time_idx ON audit_events(workspace_id, occurred_at DESC);
CREATE INDEX webhook_pending_idx ON inbound_webhook_events(next_attempt_at) WHERE status IN ('pending', 'failed');
CREATE INDEX jobs_available_idx ON background_jobs(queue, priority DESC, run_after) WHERE status IN ('pending', 'failed');
CREATE INDEX pull_requests_state_idx ON pull_requests(repository_id, state, last_synced_at DESC);

-- Keep mutable records timestamped consistently.
DO $$
DECLARE
    table_name text;
BEGIN
    FOREACH table_name IN ARRAY ARRAY[
        'users', 'workspaces', 'projects', 'access_groups', 'workflows',
        'milestones', 'sprints', 'work_items', 'project_resources',
        'project_updates', 'documents', 'diagrams', 'deliverables',
        'change_requests', 'project_feedback', 'risks',
        'integration_connections', 'repositories', 'test_suites', 'test_cases',
        'outbound_webhooks', 'intake_items', 'report_definitions',
        'automation_rules', 'background_jobs'
    ]
    LOOP
        EXECUTE format(
            'CREATE TRIGGER %I_set_updated_at BEFORE UPDATE ON %I '
            'FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
            table_name,
            table_name
        );
    END LOOP;
END;
$$;

COMMENT ON TABLE entity_visibility IS 'Explicit publication grants. Absence means internal-only.';
COMMENT ON TABLE entity_links IS 'Provider-neutral traceability graph; the application validates referenced entity existence and project ownership.';
COMMENT ON COLUMN integration_connections.credentials_ciphertext IS 'Application-layer encrypted provider credential; never plaintext.';
COMMENT ON COLUMN share_links.token_hash IS 'Hash of the bearer token; the plaintext token is shown once.';
COMMENT ON TABLE audit_events IS 'Append-only security/compliance history; application roles must not update or delete rows.';

COMMIT;
