---
title: Circuit Breaker
description: An open fake ICircuitBreaker leaves the primary off the invocations journal.
---

# Circuit Breaker

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

An open fake `ICircuitBreaker` leaves the primary off `invocations`. The fallback is on `invocations`. No `aiobreaker` extra is required.

See [Request Handler Fallback](../request_handler/fallback.md) and [Event Handler Fallback](../event_handler/fallback.md).

```python
class CircuitOpen(Exception):
    pass

class OpenCircuitBreaker:
    async def call(self, identifier, func, *args, **kwargs):
        raise CircuitOpen()

    def is_circuit_breaker_error(self, exc: Exception) -> bool:
        return isinstance(exc, CircuitOpen)

def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(
        CreateOrder,
        cqrs.RequestHandlerFallback(
            CreateOrderHandler,
            CreateOrderFallback,
            circuit_breaker=OpenCircuitBreaker(),
        ),
    )

async def test_open_circuit_breaker_skips_the_primary() -> None:
    container = di.Container()
    async with test_harness(container, commands_mapper=commands_mapper) as harness:
        await harness.mediator.send(CreateOrder(sku="book"))

        harness.invocations.assert_not_entered(CreateOrderHandler)
        harness.invocations.assert_entered(CreateOrderFallback)
```

Library example: [`examples/testing/test_fallback.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_fallback.py).
