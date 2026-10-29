# Circuit Breaker

An open fake `ICircuitBreaker` leaves the primary off `invocations`. The fallback is on `invocations`. No `aiobreaker` extra is required.

See [Request Handler Fallback](https://mkdocs.python-cqrs.dev/latest/request_handler/fallback/index.md) and [Event Handler Fallback](https://mkdocs.python-cqrs.dev/latest/event_handler/fallback/index.md).

```python
breaker = OpenCircuitBreaker()
mapper.bind(
    CreateOrder,
    cqrs.RequestHandlerFallback(
        CreateOrderHandler,
        CreateOrderFallback,
        circuit_breaker=breaker,
    ),
)
await harness.mediator.send(CreateOrder(sku="book"))
harness.invocations.assert_not_entered(CreateOrderHandler)
harness.invocations.assert_entered(CreateOrderFallback)
```

Library example: [`examples/testing/fallback.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/fallback.py).
