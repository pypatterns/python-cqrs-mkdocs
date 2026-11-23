# Message Brokers

<div class="grid cards" markdown>

-   :material-home: **Back to Bootstrap Overview**

    Return to the Bootstrap overview page with all configuration options.

    [:octicons-arrow-left-24: Back to Overview](index.md)

-   :material-message-processing: **Event Producing**

    Publishing events to Kafka, RabbitMQ, and custom brokers.

    [:octicons-arrow-right-24: Read More](../event_producing.md)

</div>

---

## Overview

[Testing Kafka and AMQP](../testing/kafka_amqp.md) uses `CapturingMessageBroker` in a unit test.

Message brokers are used to publish `NotificationEvent` and `ECSTEvent` events to external systems. The `python-cqrs` package supports multiple message broker implementations.

| Broker Type | Use Case | Production Ready |
|-------------|----------|------------------|
| **DevnullMessageBroker** | Testing, development | ❌ No |
| **KafkaMessageBroker** | High-throughput, distributed systems | ✅ Yes |
| **AMQPMessageBroker** | RabbitMQ, traditional message queues | ✅ Yes |

<details>
<summary><strong>Choosing a Message Broker</strong></summary>

<ul>
<li><strong>DevnullMessageBroker</strong>: Use for testing and development when you don't need actual message publishing</li>
<li><strong>KafkaMessageBroker</strong>: Use for high-throughput, distributed systems with strong ordering guarantees</li>
<li><strong>AMQPMessageBroker</strong>: Use for traditional message queue patterns, RabbitMQ integration</li>
</ul>

</details>

### Transport versus MessageBroker

A `MessageBroker` publishes. `send_message` is the only publish method. `KafkaMessageBroker`, `AMQPMessageBroker`, and `EventProducer` are that path.

A `Transport` is a `MessageBroker` that can also subscribe. Use it when this process receives the message, or when a test should swap the backend. `bootstrap(..., message_broker=transport)` and `test_harness(message_broker=transport)` need no new argument. Subscribe on the transport. The harness still records `published`.

`InMemoryTransport` runs the full command, saga, notification, and subscriber path in one process. `await transport.drain()` waits until handlers have acked. `delivery="inline"` makes `send_message` wait for that message and for anything the handlers published before they returned. The body a subscriber reads is bytes (`message_wire_bytes`), not a `Message` object. See [Transport](../testing/transport.md).

| Backend | Ordering per key | Native DLQ | Delayed redelivery | Headers | What `topic` means |
| --- | --- | --- | --- | --- | --- |
| In-memory | yes | no, republish to `{topic}.dlq` | yes (`redelivery_delay`) | yes | logical name shared by publisher and subscribers |
| Kafka | yes, when `key` is set (partition key) | no, republish to `{topic}.dlq` | no | yes | Kafka topic. `group` is the consumer `group_id` |
| AMQP | no. `message.key` is header `key` and does not change the route | no, republish to `{topic}.dlq` | no | yes | direct-exchange routing key. `group` is the queue name. Optional `?exchange=` on the URL |
| Redis | no. `key` is a stream field | no, republish to `{topic}.dlq` | yes (`XCLAIM` / `XAUTOCLAIM`) | yes | Redis stream key. `group` is the consumer group |
| NATS | no. `key` is a header only. An in-process per-key lock is not a cross-process guarantee | no, republish to `{topic}.dlq` | no | yes | JetStream subject as given. `group` is the durable consumer name |
| SQS | no on a standard queue. A name ending in `.fifo` also sends `MessageGroupId` | no. Emulated dead-letter queue is `{topic}-dlq` (hyphen, not a dot) | yes (visibility timeout) | yes (message attributes) | queue name, unchanged. Group fan-out on this instance is `{name}-{group}`. Dots in the name are not rewritten, and creation fails |

`create_transport` builds these from `kafka://`, `amqp://`, `redis://`, `nats://`, and `sqs://`. Install `python-cqrs[kafka]`, `[rabbit]`, `[redis]`, `[nats]`, or `[sqs]`. `KafkaMessageBroker` and `AMQPMessageBroker` stay publish-only: the AMQP broker still declares a queue named `message.topic`, and `AMQPTransport` does not replace it.

### DevnullMessageBroker

The `DevnullMessageBroker` records a message and does not deliver it. It logs a warning.

!!! warning "Deprecated when a subscriber must receive the message"
    Do not read `DevnullMessageBroker.MESSAGE_BUS`. That list does not deliver. Use `InMemoryTransport` when the message must reach a subscriber in a test or a local process. Do not use `DevnullMessageBroker` in production.

```python
from cqrs.message_brokers import devnull

mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    message_broker=devnull.DevnullMessageBroker(),
)
```

### KafkaMessageBroker

The `KafkaMessageBroker` publishes events to Apache Kafka topics.

```python
from cqrs.message_brokers import kafka
from cqrs.adapters.kafka import KafkaProducerAdapter

# Create Kafka producer adapter
kafka_producer = KafkaProducerAdapter(
    bootstrap_servers=["localhost:9092"],
    client_id="my-app",
    acks="all",  # Wait for all replicas
    enable_idempotence=True,
)

# Create message broker
kafka_broker = kafka.KafkaMessageBroker(
    producer=kafka_producer,
    aiokafka_log_level="ERROR",  # Suppress verbose logging
)

mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    domain_events_mapper=events_mapper,
    message_broker=kafka_broker,
)
```

### AMQPMessageBroker

The `AMQPMessageBroker` publishes events to RabbitMQ or other AMQP-compatible brokers.

```python
from cqrs.message_brokers import amqp
from cqrs.adapters.amqp import AMQPPublisherAdapter
import aio_pika

# Create AMQP publisher
amqp_publisher = AMQPPublisherAdapter(
    dsn="amqp://user:password@localhost/",
)

# Create message broker
amqp_broker = amqp.AMQPMessageBroker(
    publisher=amqp_publisher,
    exchange_name="events",
    pika_log_level="ERROR",
)

mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    domain_events_mapper=events_mapper,
    message_broker=amqp_broker,
)
```

### Custom Message Broker

You can create custom message brokers by implementing the `MessageBroker` protocol:

```python
from cqrs.message_brokers import protocol

class CustomMessageBroker(protocol.MessageBroker):
    async def send_message(self, message: protocol.Message) -> None:
        # Custom implementation
        print(f"Sending {message.message_name} to {message.topic}")
        # Send to your custom broker

mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    message_broker=CustomMessageBroker(),
)
```

### Event serializer (optional)

`bootstrap(..., serializer=...)` forwards a codec into `EventEmitter`. The default is JSON. Pass `OutboxedEventMap.as_serializer()` when some notification events use Protobuf — see [Protobuf Integration](../protobuf.md).
