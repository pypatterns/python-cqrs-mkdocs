# Protobuf Integration

## Overview

JSON is the default wire format for notification events. Protobuf is an **opt-in codec**: register a `ProtobufEventSerializer` for specific event names, keep everything else on JSON, and leave Kafka/AMQP frames unchanged unless the codec sets a `content_type`.

| Layer                   | JSON (default)                  | Protobuf (opt-in)                                     |
| ----------------------- | ------------------------------- | ----------------------------------------------------- |
| Outbox storage          | `orjson.dumps(event.to_dict())` | `event.proto().SerializeToString()`                   |
| `Message.payload`       | `event.to_dict()`               | still `event.to_dict()` (structured / stubs)          |
| `Message.payload_bytes` | JSON bytes                      | protobuf wire bytes                                   |
| Broker headers          | none                            | `event_name`, `message_id` when `content_type` is set |
| Consume                 | `JsonDeserializer`              | `ProtobufDeserializer`                                |

Prerequisites

Familiarity with [Transactional Outbox](https://vadikko2.github.io/python-cqrs-mkdocs/outbox/index.md) and [Event Producing](https://vadikko2.github.io/python-cqrs-mkdocs/event_producing/index.md) helps. Install the extra with `pip install "python-cqrs[protobuf]"`.

When to use

Use Protobuf for compact binary payloads and schema evolution across services. For most apps JSON is enough — do not switch globally.

## Event contract

Events that use Protobuf must implement:

- `proto()` — returns a generated protobuf message
- `from_proto(cls, proto_msg)` — rebuilds the event from that message

```python
import uuid
from datetime import datetime

import pydantic
import cqrs
from app.generated import user_joined_pb2  # generated from .proto


class UserJoinedPayload(pydantic.BaseModel, frozen=True):
    user_id: str
    meeting_id: str


class UserJoinedNotificationEvent(cqrs.NotificationEvent[UserJoinedPayload]):
    event_name: str = "user_joined"

    def proto(self):
        msg = user_joined_pb2.UserJoinedNotification()
        msg.event_id = str(self.event_id)
        msg.event_timestamp = self.event_timestamp.isoformat()
        msg.event_name = self.event_name
        msg.payload.user_id = self.payload.user_id
        msg.payload.meeting_id = self.payload.meeting_id
        return msg

    @classmethod
    def from_proto(cls, proto_msg):
        return cls(
            event_id=uuid.UUID(proto_msg.event_id),
            event_timestamp=datetime.fromisoformat(proto_msg.event_timestamp),
            event_name=proto_msg.event_name,
            topic="user_notification_events",
            payload=UserJoinedPayload(
                user_id=proto_msg.payload.user_id,
                meeting_id=proto_msg.payload.meeting_id,
            ),
        )
```

Schema assets used in examples live in [examples/proto/](https://github.com/vadikko2/python-cqrs/tree/master/examples/proto).

## Codecs

### `JsonEventSerializer`

Default codec. `content_type` is `None`, so brokers do not add MIME headers.

```python
from cqrs.serializers import JsonEventSerializer

codec = JsonEventSerializer()
wire = codec.serialize(event)          # orjson bytes of event.to_dict()
restored = codec.deserialize(wire, type(event))
```

### `ProtobufEventSerializer`

Maps event classes to generated protobuf message types. Duck-typed — does not import `google.protobuf` until you call `proto()` / `FromString`.

```python
import cqrs

proto_codec = cqrs.ProtobufEventSerializer(
    {UserJoinedNotificationEvent: user_joined_pb2.UserJoinedNotification},
)
```

`content_type` is `"application/x-protobuf"`. When that value is set on a `Message`, Kafka/AMQP also receive headers `event_name` and `message_id`.

### Protocols

- `EventSerializer` — emit-only (`serialize`, `content_type_for`)
- `EventCodec` — serialize + `deserialize` (outbox repository)

Implement these if you need a custom format.

## OutboxedEventMap and per-event codecs

`OutboxedEventMap` binds an event name to a type and an optional codec.

```python
import cqrs

events = cqrs.OutboxedEventMap()  # isolated registry (recommended)
events.register(
    "user_joined",
    UserJoinedNotificationEvent,
    serializer=cqrs.ProtobufEventSerializer(
        {UserJoinedNotificationEvent: user_joined_pb2.UserJoinedNotification},
    ),
)

# Other events can stay on the repository default (JSON):
events.register("user_left", UserLeftNotificationEvent)
```

Process-global vs isolated

Class-level `OutboxedEventMap.register(...)` mutates a process singleton (legacy behaviour). Prefer `OutboxedEventMap()` when tests or apps need isolation.

Pass the map into the repository and optionally use `as_serializer()` for the emitter:

```python
repository = cqrs.SqlAlchemyOutboxedEventRepository(
    session,
    serializer=cqrs.JsonEventSerializer(),  # fallback when register() has no codec
    event_map=events,
)

emitter = cqrs.EventEmitter(
    event_map=domain_event_map,
    container=container,
    message_broker=broker,
    serializer=events.as_serializer(default=cqrs.JsonEventSerializer()),
)
```

`OutboxedEventMap.as_serializer(default=...)` dispatches by `event.event_name`: registered codec first, otherwise the default.

Bootstrap accepts the same codec:

```python
from cqrs.requests import bootstrap

mediator = bootstrap.bootstrap(
    di_container=container,
    commands_mapper=commands_mapper,
    domain_events_mapper=domain_events_mapper,
    message_broker=broker,
    serializer=events.as_serializer(),
)
```

## Message wire shape

Emitters and the outbox producer always set both fields:

| Field                      | Role                                                                            |
| -------------------------- | ------------------------------------------------------------------------------- |
| `payload`                  | Structured dict (`event.to_dict()`) — stubs, `Message.to_dict()`, Devnull       |
| `payload_bytes`            | Codec wire bytes — what Kafka/AMQP actually publish                             |
| `content_type` / `headers` | Set only when the codec returns a MIME type (Protobuf); JSON leaves them `None` |

Brokers prefer `payload_bytes` via `message_wire_bytes()`. Ready-made `bytes` are not JSON-encoded again (`passthrough_value_serializer` on the Kafka adapter).

## Producing from outbox

Flow is unchanged: handler writes to outbox in the same DB transaction; a publisher drains rows with `EventProducer`. With a Protobuf codec registered, rows store protobuf bytes; on read, `payload_bytes` and `content_type` are restored onto `OutboxedEvent` so publish does not re-serialize.

```python
producer = cqrs.EventProducer(message_broker=broker, repository=repository)

async for batch in producer.event_batch_generator():
    for outboxed in batch:
        await producer.send_message(outboxed)
    await producer.repository.commit()
```

## Consuming with FastStream

Use `ProtobufDeserializer` as the FastStream value deserializer. It calls `from_proto` and returns `DeserializeProtobufError` on failure (same pattern as `JsonDeserializer`).

```python
import faststream
from faststream import kafka

import cqrs
from cqrs.deserializers import DeserializeProtobufError, ProtobufDeserializer
from cqrs.events import bootstrap

broker = kafka.KafkaBroker(bootstrap_servers=["localhost:9092"])
app = faststream.FastStream(broker)

def mediator_factory() -> cqrs.EventMediator:
    return bootstrap.bootstrap(
        di_container=di.Container(),
        events_mapper=events_mapper,
    )

@broker.subscriber(
    "user_notification_events",
    group_id="protobuf-consumers",
    auto_commit=False,
    value_deserializer=ProtobufDeserializer(
        UserJoinedNotificationEvent,
        user_joined_pb2.UserJoinedNotification,
    ),
)
async def handle_user_joined(
    body: UserJoinedNotificationEvent | DeserializeProtobufError | None,
    msg: kafka.KafkaMessage,
    mediator: cqrs.EventMediator = faststream.Depends(mediator_factory),
):
    if isinstance(body, DeserializeProtobufError):
        await msg.nack()
        return
    if body is None:
        await msg.ack()
        return
    await mediator.send(body)
    await msg.ack()
```

For JSON consumers see [FastStream Integration](https://vadikko2.github.io/python-cqrs-mkdocs/faststream/index.md).

## Complete local example

Produce + consume without Kafka (in-memory broker, isolated map):

```bash
pip install -e ".[examples]"
python examples/outbox/protobuf_outbox.py
```

Source: [examples/outbox/protobuf_outbox.py](https://github.com/vadikko2/python-cqrs/blob/master/examples/outbox/protobuf_outbox.py).

## Best practices

1. **Opt in per event** — register `serializer=` only for events that need Protobuf; leave the repository default as JSON.
1. **Isolated maps** — use `OutboxedEventMap()` in apps and tests; avoid the process-global singleton when possible.
1. **Keep `proto()` / `from_proto()` in sync** — every field you serialize must round-trip.
1. **Handle `DeserializeProtobufError`** — nack / DLQ on the consumer; do not assume every body is a valid event.
1. **Do not double-encode** — pass wire bytes through `payload_bytes`; do not wrap them in another JSON serializer on the producer.
1. **Headers are MIME-gated** — JSON frames stay header-free; Protobuf sets `content_type` and then `event_name` / `message_id`.

## Related

- [Transactional Outbox](https://vadikko2.github.io/python-cqrs-mkdocs/outbox/index.md) — reliable publish path that stores codec bytes
- [Event Producing](https://vadikko2.github.io/python-cqrs-mkdocs/event_producing/index.md) — brokers and `EventEmitter`
- [FastStream Integration](https://vadikko2.github.io/python-cqrs-mkdocs/faststream/index.md) — Kafka / RabbitMQ consumers
