---
title: Notification
description: Assert the notice on the published journal, including its topic.
---

# Notification

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`published` records the notice, including its topic. The notice is not in `handled`.

See [Event Types](../event_handler/event_types.md).

```python
class OrderCreatedNotice(cqrs.NotificationEvent):
    event_name: str = "order_created"
    topic: str = "order_events"

async def test_notification_is_published() -> None:
    container = di.Container()
    async with test_harness(container, commands_mapper=commands_mapper) as harness:
        await harness.mediator.send(CreateOrder(sku="book"))

        harness.published.assert_one(OrderCreatedNotice, topic="order_events")
        assert not harness.handled.contains(OrderCreatedNotice)
```

Library example: [`examples/testing/test_domain_and_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_domain_and_notification.py).
