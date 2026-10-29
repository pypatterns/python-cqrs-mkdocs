---
title: Streaming
description: Assert values on the yields journal and the event on handled.
---

# Streaming

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`yields` contains the values in order. `handled` contains `RowExported`. `clear_events` does not erase the harness record.

See [Stream Handling](../stream_handling/index.md).

A domain event from a stream is on `handled` only when its type has a handler in `domain_events_mapper`. Without one it is on `unhandled`.

```python
def streaming_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(ExportOrders, ExportOrdersHandler)

def domain_events_mapper(mapper: cqrs.EventMap) -> None:
    mapper.bind(RowExported, RowExportedHandler)

async def test_stream_records_yields_and_events() -> None:
    container = di.Container()
    async with test_harness(
        container,
        streaming_mapper=streaming_mapper,
        domain_events_mapper=domain_events_mapper,
    ) as harness:
        items = [item async for item in harness.streaming_mediator.stream(ExportOrders(batch=2))]

        assert [item.index for item in items] == [0, 1]
        assert items == harness.yields
        assert harness.handled.contains(RowExported)
```

Library example: [`examples/testing/test_streaming.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_streaming.py).
