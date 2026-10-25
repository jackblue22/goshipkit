# Job and webhook recovery

1. Identify whether the worker is still alive before changing any lease.
2. Inspect counts by queue/status and the oldest locked job.
3. Check the external provider before retrying a job with side effects.
4. Requeue leases older than the agreed timeout:

```sql
CALL goshipkit.requeue_stale_background_jobs(interval '15 minutes');
```

5. Restart one worker and watch retry/error rates before restoring full concurrency.
6. Move repeatedly failing jobs to `dead_letter`; preserve `last_error` and payload metadata for diagnosis.
7. For webhooks, reconcile provider state after recovery because event delivery order may have changed.

Do not bulk-retry unknown external side effects. Idempotency and provider reconciliation take priority over queue throughput.
