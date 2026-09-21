# Saga Fallback Pattern

- **Back to Saga Overview**

  Return to the Saga Pattern overview page with all topics.

  [Back to Overview](https://vadikko2.github.io/python-cqrs-mkdocs/saga/index.md)

The Fallback pattern allows you to define alternative steps that execute automatically when primary steps fail. This provides resilience and graceful degradation for distributed transactions.

## Overview

- **Mechanics & Internals**

  Learn about execution flow, context snapshots, and compensation logic.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/saga/fallback/mechanics/index.md)

- **Circuit Breaker**

  Understand how circuit breaker integration prevents cascading failures.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/saga/fallback/circuit_breaker/index.md)

- **Examples**

  See complete working examples of the Fallback pattern in action.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/saga/fallback/examples/index.md)

The `Fallback` wrapper enables saga steps to have backup execution paths. When a primary step fails, the fallback step executes automatically with the context restored to its state before the primary step attempted execution.

### Key Concepts

| Concept              | Description                                                                                                                                                          |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Primary Step**     | The main step handler that executes first                                                                                                                            |
| **Fallback Step**    | Alternative step handler that executes if primary fails                                                                                                              |
| **Context Snapshot** | Deep copy of context state before primary step execution                                                                                                             |
| **Context Restore**  | Restoring context to snapshot state before fallback execution                                                                                                        |
| **Circuit Breaker**  | Optional protection mechanism to prevent cascading failures                                                                                                          |
| **SEND fallback**    | Same UoW as the primary step (and domain events). After a DB error the session may need `rollback()` / a savepoint.                                                  |
| **HANDLER fallback** | New scope after the primary is **rolled back** (exception re-raised through the generator UoW). Primary writes are not visible; persist step state in `SagaContext`. |
| **NONE**             | No framework scopes.                                                                                                                                                 |

When to Use

Use Fallback pattern when:

- You have alternative execution paths for critical operations
- You want graceful degradation instead of immediate failure
- You need to protect against transient failures
- You want to reduce load on failing services with Circuit Breaker

## Basic Example

```python
import dataclasses
from cqrs.saga.fallback import Fallback
from cqrs.saga.saga import Saga
from cqrs.saga.step import SagaStepHandler, SagaStepResult
from cqrs.saga.models import SagaContext
from cqrs.response import Response

@dataclasses.dataclass
class OrderContext(SagaContext):
    order_id: str
    reservation_id: str | None = None

class ReserveInventoryResponse(Response):
    reservation_id: str

class PrimaryStep(SagaStepHandler[OrderContext, ReserveInventoryResponse]):
    async def act(self, context: OrderContext) -> SagaStepResult[OrderContext, ReserveInventoryResponse]:
        # Primary step that may fail
        reservation_id = await self._inventory_service.reserve_items(context.order_id)
        context.reservation_id = reservation_id
        return self._generate_step_result(
            ReserveInventoryResponse(reservation_id=reservation_id)
        )

class FallbackStep(SagaStepHandler[OrderContext, ReserveInventoryResponse]):
    async def act(self, context: OrderContext) -> SagaStepResult[OrderContext, ReserveInventoryResponse]:
        # Alternative step that executes when primary fails
        # Context is restored to state before primary execution
        reservation_id = f"fallback_reservation_{context.order_id}"
        context.reservation_id = reservation_id
        return self._generate_step_result(
            ReserveInventoryResponse(reservation_id=reservation_id)
        )

# Define saga with fallback
class OrderSaga(Saga[OrderContext]):
    steps = [
        Fallback(
            step=PrimaryStep,
            fallback=FallbackStep,
        ),
    ]
```

## Best Practices

1. **Use Fallback for Resilience**: Define fallback steps for critical operations that have alternative execution paths
1. **Context Isolation**: Remember that fallback receives a restored context (no side effects from failed primary)
1. **Circuit Breaker for Transient Failures**: Use Circuit Breaker when failures are likely transient and you want to reduce load on failing services
1. **Exclude Business Exceptions**: Use `exclude` parameter to prevent business logic errors from opening the circuit
1. **Idempotent Fallback Steps**: Ensure fallback steps are idempotent (safe to retry during recovery)
1. **Proper Compensation**: Define `compensate()` methods for both primary and fallback steps
1. **Failure Exception Filtering**: Use `failure_exceptions` to control which exceptions trigger fallback
1. **Match the scope strategy**: SEND shares the saga UoW with fallback; HANDLER rolls the primary back first. There is no extra fallback-scope flag.
