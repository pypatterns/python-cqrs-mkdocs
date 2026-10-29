---
title: Outbox Broker Error
description: A broker error leaves the outbox row not produced; the published journal stays empty.
---

# Outbox Broker Error

`fail_next` leaves the row `not_produced`. `published` stays empty.

See [Event Producing](../event_producing.md).

```python
harness.broker.fail_next(ConnectionError("down"))
await harness.outbox.produce_available()
assert harness.outbox.not_produced_count == 1
harness.published.assert_empty()
```

Library example: [`examples/testing/outbox_inbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/outbox_inbox.py).
