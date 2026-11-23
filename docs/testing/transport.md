---
title: Transport
description: InMemoryTransport delivers a notification to a subscriber in a unit test. drain waits for ack. The body is bytes.
---

# Transport

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`InMemoryTransport` is a `MessageBroker` that also subscribes. Pass it to `test_harness(message_broker=transport)`. The harness records `published` and still calls `send_message` on the transport, so a subscriber on that same instance receives the notice. Do not read `DevnullMessageBroker.MESSAGE_BUS`.

The subscriber sees bytes, not a `Message` and not a decoded event. Those bytes are `message_wire_bytes`: the codec payload when one was set, otherwise the JSON of `payload`. The application deserializes them. The library does not map a topic to a type.

`await transport.drain()` waits until queues are empty, no handler is running, and no redelivery is waiting. `close` stops the transport and does not deliver what is still queued. `delivery="inline"` makes `send_message` wait for this message and for anything the handlers published before they finished.

```python
import cqrs
from cqrs.testing import test_harness

transport = cqrs.InMemoryTransport()

async def on_event(message: cqrs.IncomingMessage) -> None:
    bodies.append(message.body)
    await message.ack()

async with test_harness(message_broker=transport, commands_mapper=commands_mapper) as harness:
    await transport.subscribe("order_events", on_event, cqrs.SubscribeOptions(group="billing"))
    await harness.mediator.send(CreateOrder(sku="book"))
    await transport.drain()

    harness.published.assert_one(OrderCreatedNotice, topic="order_events")
    assert len(bodies) == 1
```

`SubscribeOptions(group=...)` is required. Two groups on one topic each get a copy. Two subscribers in one group share one copy. `nack(requeue=True)` tries again until `max_deliveries`, then the message is published to `{topic}.dlq`.

Library examples: [`examples/transport/event_flow.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/transport/event_flow.py) and [`examples/transport/inbox_flow.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/transport/inbox_flow.py).

`KafkaTransport`, `AMQPTransport`, `RedisTransport`, `NATSTransport`, and `SQSTransport` are the same port on a broker. `create_transport` builds one from a URL. Ordering, dead letters, and what `topic` means are in the [capability matrix](../bootstrap/message_brokers.md#transport-versus-messagebroker). A NATS per-key lock stays inside one process. The example above stays on `InMemoryTransport` and does not start Docker.
