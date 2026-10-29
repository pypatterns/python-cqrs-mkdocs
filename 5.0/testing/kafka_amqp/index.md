# Kafka and AMQP

The harness does not import Kafka or AMQP. The unit test uses `CapturingMessageBroker` and reads `published`. The real Kafka and AMQP adapters stay in integration tests, so those clients stay out of `published`.

See [Message brokers](https://mkdocs.python-cqrs.dev/latest/bootstrap/message_brokers/index.md) and [Event producing](https://mkdocs.python-cqrs.dev/latest/event_producing/index.md).

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
