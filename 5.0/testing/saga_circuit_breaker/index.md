# Saga Circuit Breaker

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

async for step in harness.saga_mediator.execute(OrderContext(order_id="1")):
    pass

harness.invocations.assert_not_entered(ReserveStock)
harness.invocations.assert_entered(ReserveStockFallback)
```

Library example: [`examples/testing/saga.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/saga.py).
