---
title: Scope Strategies
description: Configure SEND, HANDLER, and NONE scope boundaries and override with enter_scope / bind_scope.
---

# Scope Strategies

```python
from cqrs import ScopeStrategy

mediator = bootstrap.bootstrap(
    di_container=container,
    commands_mapper=...,
    scope_strategy=ScopeStrategy.SEND,  # opt-in; default is NONE
)
```

`RequestMediator(..., scope_strategy=ScopeStrategy.SEND)`, `saga.bootstrap(..., scope_strategy=ScopeStrategy.SEND)`, and `StreamingRequestMediator(..., scope_strategy=ScopeStrategy.SEND)` work out of the box: domain events run sequentially (BFS) in the same UoW. You do **not** pass `concurrent_event_handle_enable=False` by hand.

| Strategy | Boundary | Typical use |
|----------|----------|-------------|
| **SEND** | One scope per `mediator.send()` / `stream()` including domain events **and fallback** | Outbox / shared transaction between command, fallback, and events |
| **HANDLER** | Fresh scope per resolve+handle (command, event, saga step, **and fallback**); always nested (`reuse_existing=False`) | Isolated UoW per handler |
| **NONE** (default) | No framework scopes | One-shot resolve, unchanged legacy behaviour |

## Fallback and unit of work

There is no `fallback_shares_scope` flag. The strategy already answers whether to continue the transaction or start a new one.

| Strategy | Fallback | Why |
|----------|----------|-----|
| **SEND** | Same UoW as the primary (and as domain events) | Fallback is another handler of the same `send()` / `stream()` / saga, not a new transaction. Outbox rows and partial primary writes stay in the session. After a database error the session may be in `needs rollback` — call `rollback()` or use a savepoint in the fallback, or switch to HANDLER. |
| **HANDLER** | New scope. The primary is **rolled back** first (the exception is re-raised through the generator UoW so `yield session; commit()` sees `except`, not a successful commit). Then fallback opens its own scope. | Clean alternative: “provider A failed → provider B”. Primary writes are not visible. Saga step state for compensation lives in `SagaContext`. |
| **NONE** | No framework scopes | Same one-shot resolve as today. |

On a stream, items already yielded to the client are **not** cancelled; only the unit of work changes.

## Concurrent events

`concurrent_event_handle_enable` defaults to `None` on `RequestMediator`, `StreamingRequestMediator`, `SagaMediator`, and on `saga.bootstrap` / `setup_mediator` / `setup_streaming_mediator` / `setup_saga_mediator`. `None` becomes `False` under **SEND** and `True` otherwise. Passing `concurrent_event_handle_enable=True` with **SEND** raises `ValueError` (any `max_concurrent_event_handlers`). For parallel events use **HANDLER** or **NONE**. Under SEND, multiple handlers of the same event also run sequentially (no `asyncio.gather`) so they can share that UoW.

`requests.bootstrap` still defaults concurrent processing to `False`.

!!! warning "SEND cannot run parallel event handlers"
    `ScopeStrategy.SEND` with an explicit `concurrent_event_handle_enable=True` raises `ValueError`: parallel event handlers would share one UoW/session. Omit the argument under SEND (it becomes `False`), or use `HANDLER` / `NONE` for parallel processing.

!!! note "Scopes are opt-in"
    The default is `ScopeStrategy.NONE`, so upgrading does not change how existing applications resolve dependencies. Pass `scope_strategy=ScopeStrategy.SEND` (or `HANDLER`) explicitly to make generator providers live until the scope exits.

## Streaming

- **SEND**: the mediator opens one scope around the whole stream (inside the async generator). Consume the iterator fully or close it with `aclose()` / `async with aclosing(...)`. An abandoned SEND stream holds the UoW until garbage collection; the ContextVar does not leak into the next `send()`. Prefer short-lived streams; a long open stream holds the UoW / DB session for the entire duration.
- **HANDLER**: a scope is opened around the handler stream.

```python
from contextlib import aclosing

async with aclosing(mediator.stream(command)) as stream:
    async for result in stream:
        ...
```

## Sagas

- **SEND** keeps a single scope — and therefore a single UoW — for the whole saga, including compensation and fallback. Compensation runs on the same step instance that executed `act`. This is the recommended strategy for sagas with scoped dependencies.
- **HANDLER** opens a fresh scope per step (nested even if an outer `enter_scope` / `bind_scope` is active), including fallback after the primary scope has rolled back. Compensation also runs inside a live scope, but the compensator opens a **new** scope per step and **re-resolves the step**, so `compensate` receives a different instance than `act`.

!!! warning "Do not carry state on the step instance under HANDLER"
    Under `HANDLER`, anything stored on `self` during `act` is gone by the time `compensate` runs, because the step is re-resolved in a fresh scope. Persist everything compensation needs in `SagaContext` and keep `compensate` idempotent. Under `SEND` the instance and UoW are the same as in `act`.

`saga.transaction(...)` and `recover_saga(...)` accept `scope_strategy=` (same as `SagaMediator`). Pass the **same** strategy as the original run, plus `container` and `storage`. A plain `di.Container` / `DIContainer` is enough — `SagaTransaction` wraps it internally; do **not** wrap with `ScopeAwareContainer` yourself.

```python
from cqrs import ScopeStrategy
from cqrs.saga.recovery import recover_saga

async with saga.transaction(
    context=context,
    container=plain_container,
    storage=storage,
    scope_strategy=ScopeStrategy.SEND,
) as transaction:
    async for step_result in transaction:
        ...

await recover_saga(
    saga=saga,
    saga_id=saga_id,
    context_builder=OrderContext,
    container=plain_container,
    storage=storage,
    scope_strategy=ScopeStrategy.SEND,  # must match the original run
)
```

Do not call `recover_saga` from a `send()` that already opened SEND: recovery joins that request UoW (`reuse_existing=True`).

!!! warning "`bind_scope` + HANDLER"
    `bind_scope` attaches an externally opened scope so **SEND** (or **NONE**) resolves can reuse it. Under **HANDLER**, `handler_scope` always opens a nested scope (`reuse_existing=False`), so command and domain-event handlers do **not** share that outer UoW. Use SEND when you want middleware / FastAPI scope sharing.

## Override without changing mediator config

```python
# One UoW for several commands — inner SEND scopes join the outer one
async with cqrs.enter_scope(container):
    await mediator.send(ReserveStock(...))
    await mediator.send(ChargePayment(...))

# Scope owned by FastAPI / dishka middleware — use with SEND
async with cqrs.bind_scope(DishkaCQRSContainer.of(request.state.dishka_container)):
    await mediator.send(CancelTask(task_id=task_id))
```

`enter_scope(..., reuse_existing=True)` (default) joins an already active scope instead of nesting. HANDLER never joins; it always nests.
