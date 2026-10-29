# Streaming Fallback

`yields` and `invocations` show both handlers. Values that were already yielded stay.

See [Stream Handling Fallback](https://mkdocs.python-cqrs.dev/latest/stream_handling/fallback/index.md).

```python
def streaming_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(
        ExportOrders,
        cqrs.RequestHandlerFallback(ExportOrdersHandler, ExportOrdersFallback),
    )

items = [item async for item in harness.streaming_mediator.stream(ExportOrders(batch=2))]
harness.invocations.assert_entered(ExportOrdersHandler)
harness.invocations.assert_entered(ExportOrdersFallback)
assert [item.index for item in harness.yields] == [0, 0, 1]
```

Library example: [`examples/testing/streaming.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/streaming.py).
