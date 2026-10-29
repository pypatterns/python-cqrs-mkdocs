# Outbox

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

The row is on `outbox`. `published` stays empty until `produce_available`. After that call, the status is produced and the notice is on `published`.

See [Transactional Outbox](https://mkdocs.python-cqrs.dev/latest/outbox/index.md).

Transaction log tailing is a different process, not this page; see [Transaction log tailing](https://mkdocs.python-cqrs.dev/latest/testing/log_tailing/index.md).

```python
await harness.mediator.send(CreateOrder(sku="book"))
assert harness.outbox.pending_count == 1
harness.published.assert_empty()
await harness.outbox.produce_available()
assert harness.outbox.produced_count == 1
harness.published.assert_one(OrderCreatedNotice, topic="order_events")
```

Library example: [`examples/testing/outbox_inbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/outbox_inbox.py).
