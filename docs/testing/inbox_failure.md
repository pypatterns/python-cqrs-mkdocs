---
title: Inbox Failure
description: Assert NOT_PROCESSED and flush_counter on the inbox journal.
---

# Inbox Failure

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

A handler error leaves the inbox row `NOT_PROCESSED`. `flush_counter` is `1`.

See [Using the transactional inbox](../inbox/usage.md).

```python
class FailingCreateOrderHandler(cqrs.RequestHandler[CreateOrder]):
    async def handle(self, request: CreateOrder):
        raise RuntimeError("inbox handler failed")

def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(CreateOrder, FailingCreateOrderHandler)

async def test_inbox_keeps_a_failed_row_not_processed() -> None:
    container = di.Container()
    async with test_harness(container, commands_mapper=commands_mapper) as harness:
        await harness.inbox.add([("msg-2", CreateOrder(sku="book"))])

        await harness.inbox.process_available()

        row = harness.inbox.one("msg-2")
        assert row.status is cqrs.InboxStatus.NOT_PROCESSED
        assert row.flush_counter == 1
```

Library example: [`examples/testing/test_outbox_inbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_outbox_inbox.py).
