# Usage

- **Back to Transactional Outbox Overview**

  Return to the Transactional Outbox overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/outbox/index.md)

______________________________________________________________________

## Overview

Events must be registered in `OutboxedEventMap` before they can be stored.

Prefer an **isolated** map instance. Class-level `OutboxedEventMap.register(...)` still works but mutates a process-global singleton.

```python
import cqrs
from pydantic import BaseModel

class UserJoinedPayload(BaseModel, frozen=True):
    user_id: str
    meeting_id: str

events = cqrs.OutboxedEventMap()
events.register(
    "user_joined",
    cqrs.NotificationEvent[UserJoinedPayload],
)

repository = cqrs.SqlAlchemyOutboxedEventRepository(
    session,
    event_map=events,
)
```

This registration is required for:

- Type safety when storing events
- Deserialization when reading events
- Validation of event structure

Optional `serializer=` on `register` (or the repository `serializer=` fallback) controls how payload bytes are stored. JSON is the default; Protobuf is opt-in — see [Protobuf Integration](https://mkdocs.python-cqrs.dev/latest/protobuf/index.md).

Events are published by a separate process using `EventProducer`:

```python
import asyncio
import cqrs
from cqrs.message_brokers import kafka
from cqrs.adapters import kafka as kafka_adapters

# Create message broker
broker = kafka.KafkaMessageBroker(
    producer=kafka_adapters.kafka_producer_factory(dsn="localhost:9092"),
)

# Create event producer
producer = cqrs.EventProducer(
    message_broker=broker,
    repository=outbox_repository,
)

# Publish events in batches
async def publish_events():
    async for events in producer.event_batch_generator():
        for event in events:
            await producer.send_message(event)
        await producer.repository.commit()
        await asyncio.sleep(10)  # Poll interval

asyncio.run(publish_events())
```
