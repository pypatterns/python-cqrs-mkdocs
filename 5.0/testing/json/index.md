# JSON messages

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`published` is the default path. `content_type` is `None`, and `payload["event_name"]` is `"order_created"`. `handled` stays empty.

See [Outbox usage](https://mkdocs.python-cqrs.dev/latest/outbox/usage/index.md).

```python
async def test_notification_is_published_as_json() -> None:
    container = di.Container()
    async with test_harness(container, commands_mapper=commands_mapper) as harness:
        await harness.mediator.send(CreateOrder(sku="book"))

        message = harness.published.one(OrderCreatedNotice)
        assert message.content_type is None
        assert message.payload["event_name"] == "order_created"
```

Library example: [`examples/testing/test_domain_and_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_domain_and_notification.py).
