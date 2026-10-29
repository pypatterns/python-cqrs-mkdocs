# Outbox Broker Error

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`fail_next` leaves the row `not_produced`. `published` stays empty.

See [Event Producing](https://mkdocs.python-cqrs.dev/latest/event_producing/index.md).

```python
harness.broker.fail_next(ConnectionError("down"))
await harness.outbox.produce_available()
assert harness.outbox.not_produced_count == 1
harness.published.assert_empty()
```

Library example: [`examples/testing/outbox_inbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/outbox_inbox.py).
