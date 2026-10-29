# Streaming Fallback

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`yields` and `invocations` show both handlers. Values that were already yielded stay.

See [Stream Handling Fallback](https://mkdocs.python-cqrs.dev/latest/stream_handling/fallback/index.md).

```python
def streaming_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(
        ExportOrders,
        cqrs.RequestHandlerFallback(ExportOrdersHandler, ExportOrdersFallback),
    )

async def test_stream_fallback_restarts_the_stream() -> None:
    container = di.Container()
    async with test_harness(container, streaming_mapper=streaming_mapper) as harness:
        items = [item async for item in harness.streaming_mediator.stream(ExportOrders(batch=2))]

        harness.invocations.assert_entered(ExportOrdersHandler)
        harness.invocations.assert_entered(ExportOrdersFallback)
        assert [item.index for item in harness.yields] == [0, 0, 1]
        assert [item.index for item in items] == [0, 0, 1]
```

Library example: [`examples/testing/test_streaming.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_streaming.py).
