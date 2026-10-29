---
title: Outbox Broker Error
description: A broker error leaves the outbox row not produced; the published journal stays empty.
---

# Outbox Broker Error

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`fail_next` leaves the row `not_produced`. `published` stays empty.

See [Event Producing](../event_producing.md).

```python
async def test_outbox_broker_error_leaves_the_row_not_produced() -> None:
    container = di.Container()
    async with test_harness(container, commands_mapper=commands_mapper) as harness:
        bind_outbox(container, harness.outbox_repository)
        await harness.mediator.send(CreateOrder(sku="book"))
        harness.broker.fail_next(ConnectionError("down"))

        await harness.outbox.produce_available()

        assert harness.outbox.not_produced_count == 1
        harness.published.assert_empty()
```

Library example: [`examples/testing/test_outbox_inbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_outbox_inbox.py).
