---
title: Streaming
description: Assert values on the yields journal and the event on handled.
---

# Streaming

`yields` contains the values in order. `handled` contains `RowExported`. `clear_events` does not erase the harness record.

See [Stream Handling](../stream_handling/index.md).

```python
items = [item async for item in harness.streaming_mediator.stream(ExportOrders(batch=2))]
assert [item.index for item in items] == [0, 1]
assert items == harness.yields
assert harness.handled.contains(RowExported)
```

Library example: [`examples/testing/streaming.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/streaming.py).
