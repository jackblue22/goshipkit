# ADR-0003: PostgreSQL views and worker primitives

- Status: accepted
- Date: 2026-10-26

## Context

Progress calculations must be consistent across dashboards and portals. Concurrent workers also need an atomic way to claim jobs without a separate queue service.

## Decision

Use normal security-invoker views for task-completion aggregates and PostgreSQL functions using `FOR UPDATE SKIP LOCKED` for job claims. Use a small maintenance procedure only for requeueing expired leases. Keep business workflows in Go rather than stored procedures.

## Consequences

All clients receive one explainable progress definition. Workers can scale modestly without duplicate claims. Materialized views, Redis, and a separate message broker remain optional optimizations driven by measured load.
