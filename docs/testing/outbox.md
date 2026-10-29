---
title: Outbox
description: Assert the row on the outbox journal, then the notice on published.
---

# Outbox

The row is on `outbox`. `published` stays empty until `produce_available`. After that call, the status is produced and the notice is on `published`.

See [Transactional Outbox](../outbox/index.md).

Transaction log tailing is a different process, not this page; see [Transaction log tailing](log_tailing.md).

```python
await harness.mediator.send(CreateOrder(sku="book"))
assert harness.outbox.pending_count == 1
harness.published.assert_empty()
await harness.outbox.produce_available()
assert harness.outbox.produced_count == 1
harness.published.assert_one(OrderCreatedNotice, topic="order_events")
```

Library example: [`examples/testing/outbox_inbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/outbox_inbox.py).
