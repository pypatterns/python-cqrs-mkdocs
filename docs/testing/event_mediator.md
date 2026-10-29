---
title: Event Mediator
description: Assert the handler on the invocations journal, method handle.
---

# Event Mediator

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`invocations` records the handler, and the method is `handle`. `EventMediator` goes through `EventDispatcher`, not `EventEmitter`, so this is not the `handled` journal.

See [Event Mediator](../bootstrap/event_mediator.md).

```python
def events_mapper(mapper: cqrs.EventMap) -> None:
    mapper.bind(OrderCreated, AuditHandler)

async def test_event_mediator_enters_handle() -> None:
    container = di.Container()
    async with test_harness(container, events_mapper=events_mapper) as harness:
        await harness.event_mediator.send(OrderCreated(order_id="1"))

        harness.invocations.assert_entered(AuditHandler)
        assert harness.invocations.of(AuditHandler)[0].method == "handle"
```

Library example: [`examples/testing/test_event_mediator.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_event_mediator.py).
