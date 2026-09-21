---
title: Scope Strategies
description: Choose SEND, HANDLER, or NONE — one UoW per send, per handler, or no CQRS scopes.
---

# Scope Strategies

<div class="grid cards" markdown>

-   :material-home: **Back to Scoped Dependencies Overview**

    Return to the Scoped Dependencies overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

---

```python
from cqrs import ScopeStrategy

mediator = bootstrap.bootstrap(
    di_container=container,
    commands_mapper=commands_mapper,
    scope_strategy=ScopeStrategy.SEND,  # opt-in; default is NONE
)
```

| Strategy | Boundary | Typical use |
|----------|----------|-------------|
| **SEND** | One scope per `mediator.send()` / `stream()`, including domain events **and fallback** | Outbox / one transaction for command + events |
| **HANDLER** | Fresh scope per resolve+handle (command, event, saga step, **and fallback**). Always nested. | Isolated UoW; parallel events |
| **NONE** (default) | No framework scopes | No generators; unchanged legacy resolve |

## Decision

| I need… | Use |
|---------|-----|
| Command, domain events, and outbox on one session | **SEND** ([Tutorial](tutorial.md)) |
| Fallback to start clean after the primary rolls back | **HANDLER** |
| Parallel event handlers | **HANDLER** or **NONE** — not SEND |
| No generator providers | **NONE** (omit `scope_strategy=`) |

## Fallback

There is no `fallback_shares_scope` flag — the strategy is the answer.

- **SEND** — fallback is another handler of the same `send()`. Same UoW, including a session that may need `rollback()` / a savepoint after a database error. Outbox rows from the primary stay in the session.
- **HANDLER** — the primary scope exits with **rollback** first (the generator sees `except`, not a successful commit). Then fallback opens its own scope. Primary writes are not visible.
- **NONE** — one-shot resolve, same as before scoped dependencies.

On a stream, items already yielded to the client are not cancelled; only the unit of work changes.

## Where the edge cases live

- Streams (`aclose` / `aclosing`), several `send()` calls, FastAPI `bind_scope`: [Advanced](advanced.md)
- Sagas, compensation, `recover_saga`: [Saga Recovery](../saga/recovery.md) and [Compensation](../saga/compensation.md)
- `ValueError` when SEND is combined with `concurrent_event_handle_enable=True`: [Troubleshooting](troubleshooting.md)
