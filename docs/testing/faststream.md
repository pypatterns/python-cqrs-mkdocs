---
title: FastStream
description: TestKafkaBroker delivers. The harness checks invocations or the inbox and does not import FastStream.
---

# FastStream

The harness does not import FastStream. `TestKafkaBroker` delivers the message. The event-mediator path reads `invocations`. The inbox-only subscriber reads `inbox`, and the command handler stays out of `invocations`.

See [FastStream](../faststream.md).

```python
from faststream.kafka import TestKafkaBroker

async with TestKafkaBroker(broker) as test_broker:
    async with test_harness.around(event_mediator, inbox=inbox) as harness:
        await test_broker.publish({"order_id": "1"}, "order_events")
        harness.invocations.assert_entered(AuditHandler)
```

A subscriber that only accepts the message into the inbox:

```python
await test_broker.publish({"order_id": "1"}, "order_events")
assert harness.inbox.pending_count == 1
harness.invocations.assert_not_entered(CreateOrderHandler)
```

Library example: [`examples/testing/faststream_subscriber.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/faststream_subscriber.py).
