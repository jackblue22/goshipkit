# ADR-0001: Modular monolith with multiple clients

- Status: accepted
- Date: 2026-10-26

## Context

GoShipKit targets teams of 2–10 and needs simple self-hosting. Web, Flutter mobile, and Wails desktop share one product model.

## Decision

Use one Go/Chi modular monolith and PostgreSQL database. Web, mobile, and desktop are clients of the same versioned HTTP API. Background work initially uses PostgreSQL-backed workers.

## Consequences

Deployment, local debugging, transactions, and authorization stay simple. Domain packages must keep explicit boundaries so an independently scaling worker or integration adapter can be extracted later. Microservices, Kafka, and Kubernetes are not justified for the MVP.
