# Inbox Failure

A handler error leaves the inbox row `NOT_PROCESSED`. `flush_counter` is `1`.

See [Using the transactional inbox](https://mkdocs.python-cqrs.dev/latest/inbox/usage/index.md).

```python
await harness.inbox.add([("msg-2", CreateOrder(sku="book"))])
await harness.inbox.process_available()
row = harness.inbox.one("msg-2")
assert row.status is cqrs.InboxStatus.NOT_PROCESSED
assert row.flush_counter == 1
```

Library example: [`examples/testing/outbox_inbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/outbox_inbox.py).
