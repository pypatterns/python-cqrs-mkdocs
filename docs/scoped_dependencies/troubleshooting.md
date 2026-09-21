---
title: Scoped Dependencies Troubleshooting
description: Common pitfalls with open_scope, streams, singletons, fallback UoW, and post-scope access.
---

# Troubleshooting

<div class="grid cards" markdown>

-   :material-home: **Back to Scoped Dependencies Overview**

    Return to the Scoped Dependencies overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

---

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Concurrent requests share one UoW | `open_scope` yields `self` | Always return a **new** scoped container instance |
| Cleanup never runs after early stream break | Generator not closed | Exhaust the stream or `aclose()` / `async with aclosing(...)`. SEND scope lives inside the generator body |
| Abandoned SEND stream holds a DB session | Iterator left unclosed; finally runs only on GC | Always exhaust or `aclose()` / `aclosing`. The ContextVar does **not** leak into the next `send()` |
| Same UoW for the whole process | Singleton / process-level provider | Use request-scoped providers (`di` scope `"request"`, dishka `Scope.REQUEST`) |
| Use-after-close / detached session | Accessing dependency after scope exit | Do not store scoped UoW on long-lived objects outside `handle` |
| Scopes seem to do nothing; generator provider finalizes before `handle` | `scope_strategy` not passed, so the default `NONE` is in effect | Pass `scope_strategy=ScopeStrategy.SEND` (or `HANDLER`) to bootstrap / the mediator |
| Bound `scope="request"` / dishka `Scope.REQUEST` but the session still dies before `handle` | That flag is the **DI library** lifetime. It is not a CQRS scope until `scope_strategy=` is set | Pass `scope_strategy=ScopeStrategy.SEND` (or `HANDLER`). `di` `scope=request` ≠ CQRS scope by itself |
| Event handler got a different UoW unexpectedly | `ScopeStrategy.HANDLER`, or `bind_scope` under HANDLER | Use `SEND` for a shared UoW; `bind_scope` only shares under SEND/NONE — HANDLER always nests |
| Command and its events use different UoWs although both are SEND | Hand-built `EventEmitter` created with a different `scope_strategy` than the mediator | Pass the same strategy to both (bootstrap does this for you); the mediator logs a warning on mismatch |
| `ValueError`: SEND cannot be used with `concurrent_event_handle_enable=True` | Explicit `True` with SEND (any `max`) | Omit `concurrent_event_handle_enable` under SEND (`None` → `False`). For parallel events use `HANDLER` / `NONE` |
| Fallback sees a dirty / `needs rollback` session | SEND shares the primary UoW; a DB error left the session unusable | In fallback call `rollback()` or use a savepoint, or switch to `HANDLER` for a fresh session |
| Fallback does not see primary writes; primary committed a failed unit of work | Expected under HANDLER: primary rolls back, then fallback opens a new scope | Use `SEND` if fallback must share outbox / partial writes. Persist saga state in `SagaContext` |
| Saga `compensate` sees empty/stale state set in `act` | Under `HANDLER` compensation re-resolves the step in a fresh scope, so it is a new instance | Store what compensation needs in `SagaContext`, or use `SEND` to keep one instance and UoW per saga |
| Recovery uses a different UoW / one-shot resolve | `recover_saga` called without the original `scope_strategy`, or without `container` / `storage` | Pass the **same** `scope_strategy` as the original run, plus `container` and `storage`. A plain container is enough — do not wrap `ScopeAwareContainer` yourself |
| Recovery joined an HTTP request’s UoW | `recover_saga(SEND)` called from inside `send()` / an already open SEND scope (`reuse_existing=True`) | Run recovery from a worker, not from a request that already opened SEND |
| Long-held DB session / pool exhaustion | SEND scope over a long or abandoned stream | Keep streams short; exhaust or `aclose()` the consumer promptly |
| dishka `NoFactoryError` for handlers | Handlers not registered | `provide(MyHandler, scope=Scope.REQUEST)` in a dishka `Provider` |
| `ValueError` resetting ContextVar | Async-generator context leak | Framework catches this; prefer exhausting/aclosing streams so reset runs in the same context |
| dependency-injector generators never finalize | No `SupportsScope` | Expected; switch to `di` / dishka for scoped generators |
