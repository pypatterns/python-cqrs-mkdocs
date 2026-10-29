# Saga Circuit Breaker

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

A fake `ISagaStepCircuitBreaker` leaves the primary unentered. The fallback is entered on `invocations`.

See [Circuit Breaker Integration](https://mkdocs.python-cqrs.dev/latest/saga/fallback/circuit_breaker/index.md).

```python
class OrderSaga(cqrs.Saga[OrderContext]):
    steps = [
        cqrs.saga.fallback.Fallback(
            step=ReserveStock,
            fallback=ReserveStockFallback,
            circuit_breaker=OpenSagaBreaker(),
        ),
    ]

async def test_open_saga_breaker_skips_the_step() -> None:
    container = di.Container()
    async with test_harness(container, sagas_mapper=sagas_mapper) as harness:
        async for _ in harness.saga_mediator.execute(OrderContext(order_id="1")):
            pass

        harness.invocations.assert_not_entered(ReserveStock)
        harness.invocations.assert_entered(ReserveStockFallback)
```

Library example: [`examples/testing/test_saga.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_saga.py).
