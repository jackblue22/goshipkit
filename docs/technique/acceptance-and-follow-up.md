# Acceptance and follow-up workflow

Use this pattern whenever a client, mentor, or another project stakeholder must
confirm that a result is genuinely complete. It separates an internal team
status from an external, auditable decision.

## Vocabulary

- **Done:** the team considers a work item complete. It does not imply external
  acceptance.
- **Submitted:** a specific deliverable revision is ready for stakeholder
  review.
- **Approved:** an authorized project stakeholder accepts that revision against
  its published criteria.
- **Changes requested:** the submitted revision is not accepted and must be
  revised before another decision.

Formal acceptance belongs to a deliverable or release-sized result, not every
internal task. A deliverable may link the tasks, milestone, resources, and test
evidence that explain what is being accepted.

## Authority and visibility

The project owner designates approvers through a project-scoped acceptance
capability. A role preset such as client or mentor may include that capability,
but the role name alone must not grant it. Workspace membership, a public link,
or access to an external resource never grants approval authority.

For a project without an external approver, the project owner chooses one of
these project-scoped options:

1. delegate acceptance to the team lead;
2. retain acceptance as the project owner; or
3. authorize the workspace owner for this project and its acceptance flow.

If no choice is recorded, the project owner is the default approver. “Team
lead” is an assigned project responsibility backed by capabilities, not a new
workspace-wide role. A workspace owner must still receive explicit project
access; workspace ownership alone must not reveal a private project or grant
acceptance authority.

An approver sees only the submitted revision, published acceptance criteria,
and stakeholder-visible discussion. Internal comments, draft revisions, and
unpublished evidence remain hidden. The API enforces both visibility and the
right to decide.

## Decision flow

1. The team completes its internal work and creates or updates a deliverable.
2. The team publishes the criteria and submits an immutable revision.
3. An authorized approver records either `approved` or `changes_requested`,
   with an optional decision comment.
4. `changes_requested` returns the deliverable to the team. The next submission
   creates a new revision; it does not overwrite the reviewed one.
5. `approved` closes that revision's review. The actor, decision, timestamp,
   criteria, and revision remain in the audit history.

Approval is not inferred from a task entering `Done`, a checklist being fully
checked, elapsed time, or the absence of feedback.

## Findings after approval

Never silently edit the accepted revision or erase its decision. Triage later
findings as new records and link them back to the originating deliverable or
revision:

- Create a **bug** when the delivered behavior fails an accepted criterion or
  regresses.
- Create a **task** for follow-up implementation, documentation, or operational
  work within the agreed scope.
- Create a **change request** for new or changed scope; after triage, link any
  resulting task or bug.

Generic entity links preserve this traceability without adding a dedicated
foreign key for every combination. If the follow-up produces a corrected
delivery, submit a new deliverable revision for a new decision.

## Required checks

Implementation and tests must cover:

- an authorized approver can decide on a visible submitted revision;
- a project with no client or mentor falls back to its project owner;
- a delegated project team lead can decide, while an undelegated member cannot;
- a workspace owner can decide only after explicit project authorization;
- an unauthorized user cannot decide, even if the UI control is hidden;
- members of another project cannot read or decide on the revision;
- draft and unpublished revisions are not visible to stakeholders;
- a decision is tied to exactly one revision and cannot be rewritten in place;
- post-approval bugs, tasks, and change requests retain a link to their origin.
