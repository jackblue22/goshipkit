# Progress calculation

MVP progress measures task completion, not effort or employee performance.

## Eligibility

A work item is eligible when it is not archived and its workflow status category is not `cancelled`. Epics may be excluded by the product layer when they are containers rather than executable work; the UI must disclose that choice.

```text
completed = eligible items whose status category is done
total     = all eligible items

if total = 0: progress is undefined (display “No tasks”), not 0% failure
otherwise: progress = completed / total × 100
```

The database views expose counts plus a nullable percentage. Consumers must show the counts (`8/12 tasks`) and label the percentage “task completion.”

## Later weighted progress

Weighted milestone progress belongs to L2 and must use an explicit estimate field:

```text
sum(weight of completed eligible items) / sum(weight of eligible items)
```

Never use commit count, pull-request count, online time, comment count, or time logged as an individual performance score.
