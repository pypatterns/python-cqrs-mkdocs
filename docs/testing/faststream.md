---
title: FastStream
description: TestKafkaBroker delivers. The harness checks invocations or the inbox and does not import FastStream.
---

# FastStream

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

The harness does not import FastStream. `TestKafkaBroker` delivers the message. The event-mediator path reads `invocations`. The inbox-only subscriber reads `inbox`, and the command handler stays out of `invocations`.

See [FastStream](../faststream.md).

Import the `kafka` module, not `TestKafkaBroker` itself: pytest tries to collect any `Test*` name in a test module.

```python
from faststream import kafka

async def test_subscriber_sends_the_event_to_event_mediator() -> None:
    event_mediator = events_bootstrap.bootstrap(
        di_container=di.Container(),
        events_mapper=events_mapper,
    )
    inbox = _inbox()
    broker = kafka.KafkaBroker()

    @broker.subscriber("order_events")
    async def on_order(body: dict) -> None:
        await event_mediator.send(OrderCreated(order_id=body["order_id"]))

    async with kafka.TestKafkaBroker(broker) as test_broker:
        async with test_harness.around(event_mediator, inbox=inbox) as harness:
            await test_broker.publish({"order_id": "1"}, "order_events")

            harness.invocations.assert_entered(AuditHandler)
```

A subscriber that only accepts the message into the inbox:

```python
async def test_subscriber_only_stores_the_message_in_the_inbox() -> None:
    event_mediator = events_bootstrap.bootstrap(
        di_container=di.Container(),
        events_mapper=events_mapper,
    )
    inbox = _inbox()
    broker = kafka.KafkaBroker()

    @broker.subscriber("order_events")
    async def on_order(body: dict) -> None:
        await inbox.add([("msg-1", CreateOrder(sku=body["order_id"]))])

    async with kafka.TestKafkaBroker(broker) as test_broker:
        async with test_harness.around(event_mediator, inbox=inbox) as harness:
            await test_broker.publish({"order_id": "1"}, "order_events")

            assert harness.inbox.pending_count == 1
            harness.invocations.assert_not_entered(CreateOrderHandler)
```

Library example: [`examples/testing/test_faststream_subscriber.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_faststream_subscriber.py).
