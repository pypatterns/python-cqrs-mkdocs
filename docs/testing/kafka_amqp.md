---
title: Kafka and AMQP
description: The unit test uses CapturingMessageBroker. Real Kafka and AMQP adapters stay in integration tests.
---

# Kafka and AMQP

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

The harness does not import Kafka or AMQP. The unit test uses `CapturingMessageBroker` and reads `published`. The real Kafka and AMQP adapters stay in integration tests, so those clients stay out of `published`.

See [Message brokers](../bootstrap/message_brokers.md) and [Event producing](../event_producing.md).

```python
from cqrs.testing import CapturingMessageBroker

broker = CapturingMessageBroker()
mediator = bootstrap.bootstrap(container, message_broker=broker, commands_mapper=commands_mapper)
async with test_harness.around(mediator, broker=broker) as harness:
    await mediator.send(CreateOrder(sku="book"))
    harness.published.assert_one(OrderCreatedNotice, topic="order_events")
```

`KafkaMessageBroker` construction stays in the integration tests:

```python
broker = cqrs.message_brokers.kafka.KafkaMessageBroker(producer)
mediator = bootstrap.bootstrap(container, message_broker=broker, commands_mapper=commands_mapper)
```
