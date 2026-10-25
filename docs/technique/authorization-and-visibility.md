# Authorization and visibility

Authorization is evaluated from four inputs:

```text
authenticated actor
  + workspace membership
  + project membership/capabilities
  + entity publication visibility
  = allowed action
```

## Query rule

Start every project-owned query from an authorized project set. Never fetch an entity globally by UUID and check its project afterward.

```sql
SELECT wi.*
FROM goshipkit.work_items AS wi
JOIN goshipkit.project_members AS pm
  ON pm.project_id = wi.project_id
 AND pm.user_id = $1
 AND pm.revoked_at IS NULL
 AND (pm.expires_at IS NULL OR pm.expires_at > now())
WHERE wi.id = $2;
```

The example establishes scope only; the service must also check the role/capability required by the action.

## External stakeholder reads

1. Confirm active project membership or a valid, hashed share token.
2. Resolve the actor's audience preset (`mentor`, `client`, `investor`, or `viewer`).
3. Require an active `entity_visibility` grant for that audience.
4. Apply the same rule to search, exports, notifications, activity feeds, and linked entities.
5. Treat missing visibility as `internal`; never infer publication from an external URL.

## Database versus application enforcement

The database enforces project ownership of cross-entity references. The Go permission module owns role/capability policy and must test every route. PostgreSQL RLS is intentionally deferred until request-scoped database identity and connection-pool behavior are designed; see ADR-0002.
