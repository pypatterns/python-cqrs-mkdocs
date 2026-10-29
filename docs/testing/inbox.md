---
title: Inbox
description: Assert the command on the requests journal and the processed inbox row.
---

# Inbox

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

A duplicate `add` is `False`. A command is on `requests`, and an event would be on `invocations`. The status is `PROCESSED`, and the caller commits.

See [Transactional Inbox](../inbox/index.md).

Two tests, one action each: a second `add` of the same message, and processing.

```python
async def test_inbox_rejects_a_duplicate_message() -> None:
    container = di.Container()
    async with test_harness(container, commands_mapper=commands_mapper) as harness:
        inserted = await harness.inbox.add([("msg-1", CreateOrder(sku="book"))])

        duplicate = await harness.inbox.add([("msg-1", CreateOrder(sku="book"))])

        assert inserted == [True]
        assert duplicate == [False]

async def test_inbox_processes_the_command() -> None:
    container = di.Container()
    async with test_harness(container, commands_mapper=commands_mapper) as harness:
        await harness.inbox.add([("msg-1", CreateOrder(sku="book"))])

        await harness.inbox.process_available()

        assert harness.requests.contains(CreateOrder)
        assert harness.inbox.one("msg-1").status is cqrs.InboxStatus.PROCESSED
```

Library example: [`examples/testing/test_outbox_inbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_outbox_inbox.py).
