---
title: Orchard platform — service map
---

# Orchard platform — service map

Orchard is the internal delivery platform. This page is what a maintainer opens
during an incident, at 03:00, on a phone, to answer one question: *what else
breaks if this breaks?*

## Where to start

| You need to | Go to |
| --- | --- |
| Know what a service does | [The eight services](#the-eight-services) |
| Know what breaks with it | [Service dependencies](#service-dependencies) |
| Ship a change safely | [Deploy order](#deploy-order) |
| Reach a human | [On call](#on-call) |
| Recognise a known outage | [Known failure modes](#known-failure-modes) |

## The eight services

| Service | What it does |
| --- | --- |
| `web-console` | The operator UI. Browser-facing, no API of its own. |
| `api-edge` | Public HTTP entry point. Terminates TLS, routes, rate-limits. |
| `auth-gateway` | Issues and validates session tokens. |
| `token-cache` | In-memory store for issued tokens. Loses state on restart. |
| `queue-broker` | Durable work queue. Every asynchronous job passes through it. |
| `ledger-writer` | Appends billing events. The only writer of the billing ledger. |
| `report-builder` | Renders monthly reports on demand. |
| `object-store` | Blob storage for payloads, reports and queue overflow. |

## Service dependencies

A service cannot start, and cannot serve, until everything it depends on is
healthy. Dependencies are not transitive in the table below — read the rows you
need, then read their rows.

| Service | Depends on |
| --- | --- |
| `web-console` | `api-edge` |
| `api-edge` | `auth-gateway`, `queue-broker` |
| `auth-gateway` | `token-cache` |
| `token-cache` | — |
| `queue-broker` | `object-store` |
| `ledger-writer` | `queue-broker`, `object-store` |
| `report-builder` | `auth-gateway`, `object-store` |
| `object-store` | — |

## Deploy order

Deploy from the bottom of the dependency graph upward. A service deployed
before its dependencies will start, fail its readiness probe, and be restarted
by the scheduler until it gives up.

1. `object-store` and `token-cache` — no dependencies, deploy first, in any order.
2. `queue-broker` and `auth-gateway`.
3. `api-edge`, `ledger-writer` and `report-builder`.
4. `web-console` last.

`report-builder` is the only service that can be deployed without draining
traffic: nothing depends on it, and a request in flight is retried by the
caller.

## On call

The platform rotation covers `api-edge`, `auth-gateway`, `queue-broker` and
`object-store`. The billing rotation owns `ledger-writer` alone, because a
missed billing event is not recoverable by replay.

Page the billing rotation before restarting anything that `ledger-writer`
depends on.

## Known failure modes

**`token-cache` restart logs everyone out.** It holds state only in memory.
`auth-gateway` re-issues tokens on the next request, so the outage lasts one
round trip, but every open console session is dropped.

**`object-store` throttling is silent.** The client library retries with
backoff and reports success, so the symptom is latency in `queue-broker`, not
an error in `object-store`.

**`ledger-writer` cannot catch up on its own.** After an outage it needs
`queue-broker` drained manually before it will accept new events; the
`orchard-ledger-replay` job does this.

**A `queue-broker` failover loses in-flight jobs.** Jobs already written to
`object-store` survive; jobs still in memory do not.
