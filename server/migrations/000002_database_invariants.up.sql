BEGIN;

SET search_path TO goshipkit, public;

CREATE TABLE schema_migrations (
    version text PRIMARY KEY,
    description text NOT NULL,
    checksum text,
    applied_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO schema_migrations (version, description)
VALUES
    ('000001', 'initial schema'),
    ('000002', 'database invariants, progress views, and worker primitives');

CREATE TABLE requirements (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    requirement_key varchar(32) NOT NULL,
    title text NOT NULL CHECK (length(btrim(title)) BETWEEN 1 AND 300),
    description text,
    acceptance_criteria text,
    status text NOT NULL DEFAULT 'proposed' CHECK (
        status IN ('proposed', 'approved', 'in_progress', 'implemented', 'verified', 'rejected')
    ),
    priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    owner_user_id uuid REFERENCES users(id),
    created_by uuid NOT NULL REFERENCES users(id),
    version integer NOT NULL DEFAULT 1 CHECK (version > 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    archived_at timestamptz,
    UNIQUE (project_id, requirement_key),
    CHECK (requirement_key ~ '^[A-Z][A-Z0-9_-]{0,31}$')
);

CREATE INDEX requirements_project_status_idx
    ON requirements(project_id, status, requirement_key)
    WHERE archived_at IS NULL;

CREATE INDEX requirements_search_idx
    ON requirements USING gin (
        to_tsvector('simple', title || ' ' || coalesce(description, '') || ' ' || coalesce(acceptance_criteria, ''))
    );

CREATE TRIGGER requirements_set_updated_at
BEFORE UPDATE ON requirements
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE entity_visibility
    DROP CONSTRAINT entity_visibility_entity_type_check;

ALTER TABLE entity_visibility
    ADD CONSTRAINT entity_visibility_entity_type_check CHECK (
        entity_type IN (
            'resource', 'update', 'milestone', 'work_item', 'requirement',
            'document', 'diagram', 'deliverable', 'risk', 'kpi'
        )
    );

CREATE FUNCTION entity_project_id(p_entity_type text, p_entity_id uuid)
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = goshipkit, pg_temp
AS $$
DECLARE
    resolved_project_id uuid;
BEGIN
    CASE p_entity_type
        WHEN 'project' THEN
            SELECT id INTO resolved_project_id FROM projects WHERE id = p_entity_id;
        WHEN 'requirement' THEN
            SELECT project_id INTO resolved_project_id FROM requirements WHERE id = p_entity_id;
        WHEN 'work_item' THEN
            SELECT project_id INTO resolved_project_id FROM work_items WHERE id = p_entity_id;
        WHEN 'label' THEN
            SELECT project_id INTO resolved_project_id FROM labels WHERE id = p_entity_id;
        WHEN 'milestone' THEN
            SELECT project_id INTO resolved_project_id FROM milestones WHERE id = p_entity_id;
        WHEN 'sprint' THEN
            SELECT project_id INTO resolved_project_id FROM sprints WHERE id = p_entity_id;
        WHEN 'resource' THEN
            SELECT project_id INTO resolved_project_id FROM project_resources WHERE id = p_entity_id;
        WHEN 'update' THEN
            SELECT project_id INTO resolved_project_id FROM project_updates WHERE id = p_entity_id;
        WHEN 'document' THEN
            SELECT project_id INTO resolved_project_id FROM documents WHERE id = p_entity_id;
        WHEN 'diagram' THEN
            SELECT project_id INTO resolved_project_id FROM diagrams WHERE id = p_entity_id;
        WHEN 'deliverable' THEN
            SELECT project_id INTO resolved_project_id FROM deliverables WHERE id = p_entity_id;
        WHEN 'deliverable_revision' THEN
            SELECT d.project_id INTO resolved_project_id
            FROM deliverable_revisions AS revision
            JOIN deliverables AS d ON d.id = revision.deliverable_id
            WHERE revision.id = p_entity_id;
        WHEN 'risk' THEN
            SELECT project_id INTO resolved_project_id FROM risks WHERE id = p_entity_id;
        WHEN 'kpi' THEN
            SELECT project_id INTO resolved_project_id FROM project_kpis WHERE id = p_entity_id;
        WHEN 'feedback' THEN
            SELECT project_id INTO resolved_project_id FROM project_feedback WHERE id = p_entity_id;
        WHEN 'change_request' THEN
            SELECT project_id INTO resolved_project_id FROM change_requests WHERE id = p_entity_id;
        WHEN 'repository' THEN
            SELECT project_id INTO resolved_project_id FROM repositories WHERE id = p_entity_id;
        WHEN 'branch' THEN
            SELECT repository.project_id INTO resolved_project_id
            FROM git_branches AS branch
            JOIN repositories AS repository ON repository.id = branch.repository_id
            WHERE branch.id = p_entity_id;
        WHEN 'commit' THEN
            SELECT repository.project_id INTO resolved_project_id
            FROM git_commits AS commit_record
            JOIN repositories AS repository ON repository.id = commit_record.repository_id
            WHERE commit_record.id = p_entity_id;
        WHEN 'pull_request' THEN
            SELECT repository.project_id INTO resolved_project_id
            FROM pull_requests AS pull_request
            JOIN repositories AS repository ON repository.id = pull_request.repository_id
            WHERE pull_request.id = p_entity_id;
        WHEN 'check_run' THEN
            SELECT repository.project_id INTO resolved_project_id
            FROM ci_check_runs AS check_run
            JOIN repositories AS repository ON repository.id = check_run.repository_id
            WHERE check_run.id = p_entity_id;
        WHEN 'release' THEN
            SELECT project_id INTO resolved_project_id FROM releases WHERE id = p_entity_id;
        WHEN 'test_suite' THEN
            SELECT project_id INTO resolved_project_id FROM test_suites WHERE id = p_entity_id;
        WHEN 'test_case' THEN
            SELECT project_id INTO resolved_project_id FROM test_cases WHERE id = p_entity_id;
        WHEN 'test_run' THEN
            SELECT project_id INTO resolved_project_id FROM test_runs WHERE id = p_entity_id;
        WHEN 'comment' THEN
            SELECT project_id INTO resolved_project_id FROM comments WHERE id = p_entity_id;
        ELSE
            RETURN NULL;
    END CASE;

    RETURN resolved_project_id;
END;
$$;

-- Validate denormalized project_id columns against every referenced entity.
-- Trigger arguments are pairs of entity type and NEW column name.
CREATE FUNCTION enforce_row_project_references()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = goshipkit, pg_temp
AS $$
DECLARE
    expected_project_id uuid := nullif(to_jsonb(NEW) ->> 'project_id', '')::uuid;
    referenced_entity_id uuid;
    referenced_project_id uuid;
    argument_index integer := 0;
BEGIN
    IF TG_NARGS = 0 OR TG_NARGS % 2 <> 0 THEN
        RAISE EXCEPTION 'project reference guard requires entity-type/column pairs';
    END IF;

    WHILE argument_index < TG_NARGS LOOP
        referenced_entity_id := nullif(to_jsonb(NEW) ->> TG_ARGV[argument_index + 1], '')::uuid;
        IF referenced_entity_id IS NOT NULL THEN
            referenced_project_id := entity_project_id(TG_ARGV[argument_index], referenced_entity_id);
            IF referenced_project_id IS DISTINCT FROM expected_project_id THEN
                RAISE EXCEPTION '%.% must reference the same project', TG_TABLE_NAME, TG_ARGV[argument_index + 1]
                    USING ERRCODE = '23514';
            END IF;
        END IF;
        argument_index := argument_index + 2;
    END LOOP;

    RETURN NEW;
END;
$$;

-- Validate join tables that do not repeat project_id. Trigger arguments use
-- the same entity-type/column pairs as enforce_row_project_references().
CREATE FUNCTION enforce_same_project_references()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = goshipkit, pg_temp
AS $$
DECLARE
    expected_project_id uuid;
    referenced_entity_id uuid;
    referenced_project_id uuid;
    argument_index integer := 0;
BEGIN
    IF TG_NARGS < 4 OR TG_NARGS % 2 <> 0 THEN
        RAISE EXCEPTION 'same-project guard requires at least two entity-type/column pairs';
    END IF;

    WHILE argument_index < TG_NARGS LOOP
        referenced_entity_id := nullif(to_jsonb(NEW) ->> TG_ARGV[argument_index + 1], '')::uuid;
        IF referenced_entity_id IS NOT NULL THEN
            referenced_project_id := entity_project_id(TG_ARGV[argument_index], referenced_entity_id);
            IF referenced_project_id IS NULL THEN
                RAISE EXCEPTION 'unknown %.% reference', TG_TABLE_NAME, TG_ARGV[argument_index + 1]
                    USING ERRCODE = '23503';
            END IF;
            IF expected_project_id IS NULL THEN
                expected_project_id := referenced_project_id;
            ELSIF referenced_project_id <> expected_project_id THEN
                RAISE EXCEPTION '%.% cannot cross project boundaries', TG_TABLE_NAME, TG_ARGV[argument_index + 1]
                    USING ERRCODE = '23514';
            END IF;
        END IF;
        argument_index := argument_index + 2;
    END LOOP;

    RETURN NEW;
END;
$$;

CREATE TRIGGER project_updates_reference_guard
BEFORE INSERT OR UPDATE OF project_id, milestone_id ON project_updates
FOR EACH ROW EXECUTE FUNCTION enforce_row_project_references('milestone', 'milestone_id');

CREATE TRIGGER documents_reference_guard
BEFORE INSERT OR UPDATE OF project_id, parent_id ON documents
FOR EACH ROW EXECUTE FUNCTION enforce_row_project_references('document', 'parent_id');

CREATE TRIGGER deliverables_reference_guard
BEFORE INSERT OR UPDATE OF project_id, milestone_id ON deliverables
FOR EACH ROW EXECUTE FUNCTION enforce_row_project_references('milestone', 'milestone_id');

CREATE TRIGGER project_feedback_reference_guard
BEFORE INSERT OR UPDATE OF project_id, milestone_id, update_id ON project_feedback
FOR EACH ROW EXECUTE FUNCTION enforce_row_project_references(
    'milestone', 'milestone_id', 'update', 'update_id'
);

CREATE TRIGGER comments_reference_guard
BEFORE INSERT OR UPDATE OF project_id, parent_id, work_item_id, update_id, feedback_id, change_request_id ON comments
FOR EACH ROW EXECUTE FUNCTION enforce_row_project_references(
    'comment', 'parent_id',
    'work_item', 'work_item_id',
    'update', 'update_id',
    'feedback', 'feedback_id',
    'change_request', 'change_request_id'
);

CREATE TRIGGER releases_reference_guard
BEFORE INSERT OR UPDATE OF project_id, repository_id, milestone_id ON releases
FOR EACH ROW EXECUTE FUNCTION enforce_row_project_references(
    'repository', 'repository_id', 'milestone', 'milestone_id'
);

CREATE TRIGGER test_cases_reference_guard
BEFORE INSERT OR UPDATE OF project_id, suite_id, work_item_id ON test_cases
FOR EACH ROW EXECUTE FUNCTION enforce_row_project_references(
    'test_suite', 'suite_id', 'work_item', 'work_item_id'
);

CREATE TRIGGER test_runs_reference_guard
BEFORE INSERT OR UPDATE OF project_id, release_id, deliverable_revision_id ON test_runs
FOR EACH ROW EXECUTE FUNCTION enforce_row_project_references(
    'release', 'release_id', 'deliverable_revision', 'deliverable_revision_id'
);

CREATE TRIGGER work_item_labels_project_guard
BEFORE INSERT OR UPDATE OF work_item_id, label_id ON work_item_labels
FOR EACH ROW EXECUTE FUNCTION enforce_same_project_references(
    'work_item', 'work_item_id', 'label', 'label_id'
);

CREATE TRIGGER work_item_relations_project_guard
BEFORE INSERT OR UPDATE OF source_id, target_id ON work_item_relations
FOR EACH ROW EXECUTE FUNCTION enforce_same_project_references(
    'work_item', 'source_id', 'work_item', 'target_id'
);

CREATE TRIGGER deliverable_resources_project_guard
BEFORE INSERT OR UPDATE OF deliverable_revision_id, resource_id ON deliverable_resources
FOR EACH ROW EXECUTE FUNCTION enforce_same_project_references(
    'deliverable_revision', 'deliverable_revision_id', 'resource', 'resource_id'
);

CREATE TRIGGER ci_check_runs_project_guard
BEFORE INSERT OR UPDATE OF repository_id, pull_request_id ON ci_check_runs
FOR EACH ROW EXECUTE FUNCTION enforce_same_project_references(
    'repository', 'repository_id', 'pull_request', 'pull_request_id'
);

CREATE TRIGGER test_results_project_guard
BEFORE INSERT OR UPDATE OF test_run_id, test_case_id ON test_results
FOR EACH ROW EXECUTE FUNCTION enforce_same_project_references(
    'test_run', 'test_run_id', 'test_case', 'test_case_id'
);

CREATE FUNCTION enforce_repository_connection_scope()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = goshipkit, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM projects AS project
        JOIN integration_connections AS connection
          ON connection.workspace_id = project.workspace_id
        WHERE project.id = NEW.project_id AND connection.id = NEW.connection_id
    ) THEN
        RAISE EXCEPTION 'repository connection must belong to the project workspace'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER repositories_connection_scope_guard
BEFORE INSERT OR UPDATE OF project_id, connection_id ON repositories
FOR EACH ROW EXECUTE FUNCTION enforce_repository_connection_scope();

CREATE FUNCTION enforce_workflow_transition_scope()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = goshipkit, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM workflow_statuses
        WHERE id = NEW.from_status_id AND workflow_id = NEW.workflow_id
    ) OR NOT EXISTS (
        SELECT 1 FROM workflow_statuses
        WHERE id = NEW.to_status_id AND workflow_id = NEW.workflow_id
    ) THEN
        RAISE EXCEPTION 'workflow transition statuses must belong to the same workflow'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER workflow_transitions_scope_guard
BEFORE INSERT OR UPDATE OF workflow_id, from_status_id, to_status_id ON workflow_transitions
FOR EACH ROW EXECUTE FUNCTION enforce_workflow_transition_scope();

CREATE FUNCTION enforce_generic_entity_scope()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = goshipkit, pg_temp
AS $$
DECLARE
    resolved_project_id uuid;
BEGIN
    IF TG_TABLE_NAME = 'entity_visibility' THEN
        resolved_project_id := entity_project_id(NEW.entity_type, NEW.entity_id);
        IF resolved_project_id IS NULL THEN
            RAISE EXCEPTION 'unknown %.entity reference: %', NEW.entity_type, NEW.entity_id
                USING ERRCODE = '23503';
        END IF;
        IF resolved_project_id <> NEW.project_id THEN
            RAISE EXCEPTION 'entity visibility cannot cross project boundaries'
                USING ERRCODE = '23514';
        END IF;
        IF NEW.entity_type = 'update' AND NOT EXISTS (
            SELECT 1 FROM project_updates WHERE id = NEW.entity_id AND status = 'published'
        ) THEN
            RAISE EXCEPTION 'draft project updates cannot be published to stakeholders'
                USING ERRCODE = '23514';
        END IF;
    ELSE
        resolved_project_id := entity_project_id(NEW.source_type, NEW.source_id);
        IF resolved_project_id IS NULL THEN
            RAISE EXCEPTION 'unknown source entity %.%', NEW.source_type, NEW.source_id
                USING ERRCODE = '23503';
        END IF;
        IF resolved_project_id <> NEW.project_id THEN
            RAISE EXCEPTION 'source entity cannot cross project boundaries'
                USING ERRCODE = '23514';
        END IF;

        resolved_project_id := entity_project_id(NEW.target_type, NEW.target_id);
        IF resolved_project_id IS NULL THEN
            RAISE EXCEPTION 'unknown target entity %.%', NEW.target_type, NEW.target_id
                USING ERRCODE = '23503';
        END IF;
        IF resolved_project_id <> NEW.project_id THEN
            RAISE EXCEPTION 'target entity cannot cross project boundaries'
                USING ERRCODE = '23514';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER entity_visibility_scope_guard
BEFORE INSERT OR UPDATE OF project_id, entity_type, entity_id ON entity_visibility
FOR EACH ROW EXECUTE FUNCTION enforce_generic_entity_scope();

CREATE TRIGGER entity_links_scope_guard
BEFORE INSERT OR UPDATE OF project_id, source_type, source_id, target_type, target_id ON entity_links
FOR EACH ROW EXECUTE FUNCTION enforce_generic_entity_scope();

CREATE FUNCTION enforce_work_item_project_scope()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = goshipkit, pg_temp
AS $$
DECLARE
    resolved_project_id uuid;
BEGIN
    SELECT workflow.project_id INTO resolved_project_id
    FROM workflow_statuses AS status
    JOIN workflows AS workflow ON workflow.id = status.workflow_id
    WHERE status.id = NEW.status_id;

    IF resolved_project_id IS NULL OR resolved_project_id <> NEW.project_id THEN
        RAISE EXCEPTION 'work-item status must belong to the same project'
            USING ERRCODE = '23514';
    END IF;
    IF NEW.parent_id IS NOT NULL
       AND entity_project_id('work_item', NEW.parent_id) IS DISTINCT FROM NEW.project_id THEN
        RAISE EXCEPTION 'parent work item must belong to the same project'
            USING ERRCODE = '23514';
    END IF;
    IF NEW.epic_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM work_items
        WHERE id = NEW.epic_id AND project_id = NEW.project_id AND type = 'epic'
    ) THEN
        RAISE EXCEPTION 'epic must be an epic in the same project'
            USING ERRCODE = '23514';
    END IF;
    IF NEW.milestone_id IS NOT NULL
       AND entity_project_id('milestone', NEW.milestone_id) IS DISTINCT FROM NEW.project_id THEN
        RAISE EXCEPTION 'milestone must belong to the same project'
            USING ERRCODE = '23514';
    END IF;
    IF NEW.sprint_id IS NOT NULL
       AND entity_project_id('sprint', NEW.sprint_id) IS DISTINCT FROM NEW.project_id THEN
        RAISE EXCEPTION 'sprint must belong to the same project'
            USING ERRCODE = '23514';
    END IF;
    IF NEW.assignee_user_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM project_members
        WHERE project_id = NEW.project_id
          AND user_id = NEW.assignee_user_id
          AND revoked_at IS NULL
          AND (expires_at IS NULL OR expires_at > now())
    ) THEN
        RAISE EXCEPTION 'assignee must be an active project member'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER work_items_project_scope_guard
BEFORE INSERT OR UPDATE OF project_id, status_id, parent_id, epic_id, milestone_id, sprint_id, assignee_user_id
ON work_items
FOR EACH ROW EXECUTE FUNCTION enforce_work_item_project_scope();

CREATE FUNCTION protect_audit_events()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = goshipkit, pg_temp
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'audit events are append-only' USING ERRCODE = '55000';
    END IF;

    IF (to_jsonb(NEW) - ARRAY['workspace_id', 'project_id', 'actor_user_id']::text[])
       IS DISTINCT FROM
       (to_jsonb(OLD) - ARRAY['workspace_id', 'project_id', 'actor_user_id']::text[])
       OR NOT (NEW.workspace_id IS NOT DISTINCT FROM OLD.workspace_id OR NEW.workspace_id IS NULL)
       OR NOT (NEW.project_id IS NOT DISTINCT FROM OLD.project_id OR NEW.project_id IS NULL)
       OR NOT (NEW.actor_user_id IS NOT DISTINCT FROM OLD.actor_user_id OR NEW.actor_user_id IS NULL) THEN
        RAISE EXCEPTION 'audit events are append-only' USING ERRCODE = '55000';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER audit_events_append_only_guard
BEFORE UPDATE OR DELETE ON audit_events
FOR EACH ROW EXECUTE FUNCTION protect_audit_events();

CREATE VIEW active_project_members
WITH (security_invoker = true)
AS
SELECT project_id, user_id, role, permissions, invited_by, joined_at, expires_at
FROM project_members
WHERE revoked_at IS NULL
  AND (expires_at IS NULL OR expires_at > now());

CREATE VIEW project_task_progress
WITH (security_invoker = true)
AS
SELECT
    item.project_id,
    count(*) FILTER (WHERE status.category <> 'cancelled') AS total_tasks,
    count(*) FILTER (WHERE status.category = 'done') AS completed_tasks,
    count(*) FILTER (
        WHERE status.category NOT IN ('done', 'cancelled') AND item.due_at < now()
    ) AS overdue_tasks,
    round(
        100.0 * count(*) FILTER (WHERE status.category = 'done')
        / NULLIF(count(*) FILTER (WHERE status.category <> 'cancelled'), 0),
        2
    ) AS completion_percent
FROM work_items AS item
JOIN workflow_statuses AS status ON status.id = item.status_id
WHERE item.archived_at IS NULL
GROUP BY item.project_id;

CREATE VIEW milestone_task_progress
WITH (security_invoker = true)
AS
SELECT
    item.project_id,
    item.milestone_id,
    count(*) FILTER (WHERE status.category <> 'cancelled') AS total_tasks,
    count(*) FILTER (WHERE status.category = 'done') AS completed_tasks,
    count(*) FILTER (
        WHERE status.category NOT IN ('done', 'cancelled') AND item.due_at < now()
    ) AS overdue_tasks,
    round(
        100.0 * count(*) FILTER (WHERE status.category = 'done')
        / NULLIF(count(*) FILTER (WHERE status.category <> 'cancelled'), 0),
        2
    ) AS completion_percent
FROM work_items AS item
JOIN workflow_statuses AS status ON status.id = item.status_id
WHERE item.archived_at IS NULL AND item.milestone_id IS NOT NULL
GROUP BY item.project_id, item.milestone_id;

CREATE INDEX background_jobs_running_lease_idx
    ON background_jobs(locked_at)
    WHERE status = 'running';

CREATE FUNCTION claim_background_jobs(
    p_worker_id text,
    p_queues text[] DEFAULT NULL,
    p_limit integer DEFAULT 10
)
RETURNS SETOF background_jobs
LANGUAGE plpgsql
VOLATILE
SET search_path = goshipkit, pg_temp
AS $$
BEGIN
    IF p_worker_id IS NULL OR btrim(p_worker_id) = '' THEN
        RAISE EXCEPTION 'worker id is required' USING ERRCODE = '22023';
    END IF;
    IF p_limit NOT BETWEEN 1 AND 100 THEN
        RAISE EXCEPTION 'claim limit must be between 1 and 100' USING ERRCODE = '22023';
    END IF;

    RETURN QUERY
    WITH candidates AS (
        SELECT id
        FROM background_jobs
        WHERE status IN ('pending', 'failed')
          AND attempts < max_attempts
          AND run_after <= now()
          AND (p_queues IS NULL OR queue = ANY(p_queues))
        ORDER BY priority DESC, run_after, created_at
        FOR UPDATE SKIP LOCKED
        LIMIT p_limit
    )
    UPDATE background_jobs AS jobs
    SET status = 'running',
        attempts = jobs.attempts + 1,
        locked_at = now(),
        locked_by = p_worker_id,
        updated_at = now()
    FROM candidates
    WHERE jobs.id = candidates.id
    RETURNING jobs.*;
END;
$$;

CREATE PROCEDURE requeue_stale_background_jobs(
    p_lease_timeout interval DEFAULT interval '15 minutes'
)
LANGUAGE plpgsql
SET search_path = goshipkit, pg_temp
AS $$
BEGIN
    IF p_lease_timeout <= interval '0 seconds' THEN
        RAISE EXCEPTION 'lease timeout must be positive' USING ERRCODE = '22023';
    END IF;

    UPDATE background_jobs
    SET status = CASE WHEN attempts >= max_attempts THEN 'dead_letter' ELSE 'failed' END,
        run_after = CASE WHEN attempts >= max_attempts THEN run_after ELSE now() END,
        locked_at = NULL,
        locked_by = NULL,
        last_error = concat_ws(E'\n', nullif(last_error, ''), 'worker lease expired'),
        updated_at = now()
    WHERE status = 'running'
      AND locked_at < now() - p_lease_timeout;
END;
$$;

COMMENT ON TABLE requirements IS 'Project-scoped requirements used by the traceability graph.';
COMMENT ON FUNCTION entity_project_id(text, uuid) IS 'Resolves supported generic entity references to their owning project.';
COMMENT ON VIEW project_task_progress IS 'Task-count project progress; cancelled and archived work is excluded from the denominator.';
COMMENT ON VIEW milestone_task_progress IS 'Task-count milestone progress; cancelled and archived work is excluded from the denominator.';
COMMENT ON FUNCTION claim_background_jobs(text, text[], integer) IS 'Atomically leases runnable jobs using SKIP LOCKED.';
COMMENT ON PROCEDURE requeue_stale_background_jobs(interval) IS 'Releases expired worker leases and dead-letters exhausted jobs.';

COMMIT;
