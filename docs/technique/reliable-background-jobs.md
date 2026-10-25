# Reliable background jobs and webhooks

GoShipKit uses the PostgreSQL `background_jobs` table before introducing a separate queue service.

## Enqueue atomically

Insert the domain change and its background job in the same transaction. This provides a transactional-outbox pattern without a second table: either both commit or neither does.

Use a stable idempotency key inside the job payload for externally visible actions. Consumers must be safe to retry because a worker can finish an external request and crash before committing completion.

## Claim concurrently

Workers call `claim_background_jobs(...)`, which uses `FOR UPDATE SKIP LOCKED`. A claim sets the worker ID, increments attempts, and changes status to `running` in one statement.

## Retry and recovery

- Use bounded exponential backoff with jitter.
- Stop at `max_attempts` and mark the job `dead_letter`.
- Reconcile provider state after missed or ambiguous webhook events.
- Verify webhook signatures before enqueueing domain work.
- Deduplicate inbound events by `(connection_id, provider_event_id)`.
- Use `CALL requeue_stale_background_jobs(...)` only after confirming the original worker no longer owns the lease.

See the [job recovery runbook](../runbooks/job-recovery.md).
