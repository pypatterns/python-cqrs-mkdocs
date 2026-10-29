# Unhandled Event

The event type is on `unhandled`. `send` does not raise. The handler is not on `invocations`.

See [Event Flow](https://mkdocs.python-cqrs.dev/latest/event_handler/event_flow/index.md).

```python
await harness.mediator.send(CreateOrder(sku="book"))
assert harness.unhandled.contains(OrderCreated)
harness.invocations.assert_not_entered(AuditHandler)
```

Library example: [`examples/testing/domain_and_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/domain_and_notification.py).
