# Request Fallback

Both classes are on `invocations`. The response on `requests` is the fallback's.

See [Request Handler Fallback](https://mkdocs.python-cqrs.dev/latest/request_handler/fallback/index.md).

```python
def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(
        CreateOrder,
        cqrs.RequestHandlerFallback(CreateOrderHandler, CreateOrderFallback),
    )

result = await harness.mediator.send(CreateOrder(sku="book"))
assert result.source == "fallback"
harness.invocations.assert_entered(CreateOrderHandler)
harness.invocations.assert_entered(CreateOrderFallback)
```

Library example: [`examples/testing/fallback.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/fallback.py).
