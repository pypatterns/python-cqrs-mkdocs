---
title: Inbox
description: Assert the command on the requests journal and the processed inbox row.
---

# Inbox

A duplicate `add` is `False`. A command is on `requests`, and an event would be on `invocations`. The status is `PROCESSED`, and the caller commits.

See [Transactional Inbox](../inbox/index.md).

```python
inserted = await harness.inbox.add([("msg-1", CreateOrder(sku="book"))])
assert inserted == [True]
duplicate = await harness.inbox.add([("msg-1", CreateOrder(sku="book"))])
assert duplicate == [False]
await harness.inbox.process_available()
assert harness.requests.contains(CreateOrder)
assert harness.inbox.one("msg-1").status is cqrs.InboxStatus.PROCESSED
```

Library example: [`examples/testing/outbox_inbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/outbox_inbox.py).
