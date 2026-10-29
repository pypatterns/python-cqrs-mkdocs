---
title: JSON messages
description: Default path for a published message. content_type is None.
---

# JSON messages

`published` is the default path. `content_type` is `None`, and `payload["event_name"]` is `"order_created"`. `handled` stays empty.

See [Outbox usage](../outbox/usage.md).

```python
await harness.mediator.send(CreateOrder(sku="book"))
message = harness.published.one(OrderCreatedNotice)
assert message.content_type is None
assert message.payload["event_name"] == "order_created"
```

Library example: [`examples/testing/domain_and_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/domain_and_notification.py).
