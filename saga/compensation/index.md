# Compensation Strategy

- **Back to Saga Overview**

  Return to the Saga Pattern overview page with all topics.

  [Back to Overview](https://vadikko2.github.io/python-cqrs-mkdocs/saga/index.md)

Compensation undoes the effects of completed steps when a saga fails, ensuring resources are properly released and the system returns to a consistent state.

When the storage supports **`create_run()`**, the saga runs compensation within a single storage run and persists each successfully compensated step at a **checkpoint** (by committing the run after each step). This keeps the number of commits low and aligns with the checkpoint model used for forward execution.

## Overview

When any step fails, all previously completed steps are automatically compensated in **reverse order**:

- Resources are properly released
- Partial operations are rolled back
- System returns to a consistent state

## How Compensation Works

Compensation is triggered automatically when a step's `act()` method raises an exception:

```
sequenceDiagram
    participant Transaction as SagaTransaction
    participant Step1 as Step 1
    participant Step2 as Step 2
    participant Step3 as Step 3

    Transaction->>Step1: act(context)
    Step1-->>Transaction: Success ✓
    Transaction->>Step2: act(context)
    Step2-->>Transaction: Success ✓
    Transaction->>Step3: act(context)
    Step3-->>Transaction: Exception ✗

    Note over Transaction: Compensation triggered

    Transaction->>Step2: compensate(context)
    Transaction->>Step1: compensate(context)
    Transaction-->>Transaction: Mark saga as FAILED
```

Compensation happens in **reverse order**:

```text
Execution:    Step 1 → Step 2 → Step 3
Compensation: Step 3 ← Step 2 ← Step 1
```

## Implementing Compensation

Each step handler must implement the `compensate()` method:

```python
class ReserveInventoryStep(SagaStepHandler[OrderContext, Response]):
    async def act(self, context: OrderContext) -> SagaStepResult:
        reservation_id = await self._inventory_service.reserve_items(
            context.order_id, context.items
        )
        context.inventory_reservation_id = reservation_id
        return self._generate_step_result(Response())

    async def compensate(self, context: OrderContext) -> None:
        if context.inventory_reservation_id:
            await self._inventory_service.release_items(
                context.inventory_reservation_id
            )
```

### Best Practices

1. **Idempotent** — Safe to call multiple times
1. **Check Context** — Verify compensation is needed before executing
1. **Handle Errors** — Gracefully handle missing resources

### Idempotent Example

```python
async def compensate(self, context: OrderContext) -> None:
    if not context.inventory_reservation_id:
        return  # Already compensated

    try:
        await self._inventory_service.release_items(
            context.inventory_reservation_id
        )
        context.inventory_reservation_id = None
    except ValueError:
        pass  # Already released - idempotent
```

## Compensation Retry

Automatic retry for compensation failures is configured on **`saga.transaction(...)`**:

```python
from cqrs import ScopeStrategy

saga = OrderSaga()  # steps defined on class

async with saga.transaction(
    context=context,
    container=container,
    storage=storage,
    scope_strategy=ScopeStrategy.SEND,  # same as the original run; plain container is enough
    compensation_retry_count=3,      # Number of retry attempts
    compensation_retry_delay=1.0,   # Initial delay in seconds
    compensation_retry_backoff=2.0, # Exponential backoff multiplier
) as transaction:
    async for step_result in transaction:
        ...
```

**Retry schedule:**

- Attempt 1: fails, wait 1.0s
- Attempt 2: fails, wait 2.0s (1.0 × 2.0)
- Attempt 3: fails, wait 4.0s (2.0 × 2.0)
- Attempt 4: final attempt

## Compensation Patterns

### Direct Reversal

```python
async def act(self, context: OrderContext) -> SagaStepResult:
    resource_id = await service.create_resource(data)
    context.resource_id = resource_id
    return self._generate_step_result(Response())

async def compensate(self, context: OrderContext) -> None:
    if context.resource_id:
        await service.delete_resource(context.resource_id)
```

### Compensating Transaction

```python
async def act(self, context: OrderContext) -> SagaStepResult:
    payment_id = await payment_service.charge(amount)
    context.payment_id = payment_id
    return self._generate_step_result(Response())

async def compensate(self, context: OrderContext) -> None:
    if context.payment_id:
        await payment_service.refund(context.payment_id)
```

### No-Op Compensation

```python
async def act(self, context: OrderContext) -> SagaStepResult:
    await notification_service.send(context.user_id, message)
    return self._generate_step_result(Response())

async def compensate(self, context: OrderContext) -> None:
    pass  # Notifications can't be "unsent"
```

## Common Pitfalls

### Non-Idempotent Compensation

```python
# ❌ Bad: Not idempotent
async def compensate(self, context: OrderContext) -> None:
    await service.delete_resource(context.resource_id)

# ✅ Good: Idempotent
async def compensate(self, context: OrderContext) -> None:
    if context.resource_id:
        try:
            await service.delete_resource(context.resource_id)
        except NotFoundError:
            pass
        context.resource_id = None
```

### Missing Context Check

```python
# ❌ Bad: May fail if resource doesn't exist
async def compensate(self, context: OrderContext) -> None:
    await service.release_items(context.inventory_reservation_id)

# ✅ Good: Checks before compensating
async def compensate(self, context: OrderContext) -> None:
    if context.inventory_reservation_id:
        await service.release_items(context.inventory_reservation_id)
```

## Scoped compensation

- **SEND** — compensation runs on the **same step instance and UoW** as `act` (one saga scope).
- **HANDLER** — each step (and compensation) is re-resolved in a **fresh** scope, so `self` state from `act` is gone. Persist what `compensate` needs in `SagaContext` and keep compensation idempotent.
- **NONE** — no framework scopes.

Do not wrap the container with `ScopeAwareContainer` yourself; `saga.transaction` wraps a plain container internally. See [Scope Strategies](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/strategies/index.md).

## Best Practices

1. **Idempotent** — Safe to call multiple times
1. **Check Context** — Verify compensation is needed
1. **Handle Failures** — Log errors appropriately
1. **Test Logic** — Ensure compensation works correctly
1. **Match `scope_strategy`** — Pass the same strategy as the original run; under HANDLER do not store compensation state on `self`
