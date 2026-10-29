---
title: Unhandled Event
description: Assert the event type on the unhandled journal.
---

# Unhandled Event

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

The event type is on `unhandled`. `send` does not raise. The handler is not on `invocations`.

See [Event Flow](../event_handler/event_flow.md).

```python
async def test_event_without_handler_is_unhandled() -> None:
    container = di.Container()
    async with test_harness(container, commands_mapper=commands_mapper) as harness:
        await harness.mediator.send(CreateOrder(sku="book"))

        assert harness.unhandled.contains(OrderCreated)
        harness.invocations.assert_not_entered(AuditHandler)
```

Library example: [`examples/testing/test_domain_and_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_domain_and_notification.py).
