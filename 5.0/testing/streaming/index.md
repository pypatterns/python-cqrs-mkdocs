# Streaming

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`yields` contains the values in order. `handled` contains `RowExported`. `clear_events` does not erase the harness record.

See [Stream Handling](https://mkdocs.python-cqrs.dev/latest/stream_handling/index.md).

```python
items = [item async for item in harness.streaming_mediator.stream(ExportOrders(batch=2))]
assert [item.index for item in items] == [0, 1]
assert items == harness.yields
assert harness.handled.contains(RowExported)
```

Library example: [`examples/testing/streaming.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/streaming.py).
