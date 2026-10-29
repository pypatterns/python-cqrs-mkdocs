# Notification

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`published` records the notice, including its topic. The notice is not in `handled`.

See [Event Types](https://mkdocs.python-cqrs.dev/latest/event_handler/event_types/index.md).

```python
class OrderCreatedNotice(cqrs.NotificationEvent):
    event_name: str = "order_created"
    topic: str = "order_events"

await harness.mediator.send(CreateOrder(sku="book"))
harness.published.assert_one(OrderCreatedNotice, topic="order_events")
assert not harness.handled.contains(OrderCreatedNotice)
```

Library example: [`examples/testing/domain_and_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/domain_and_notification.py).
