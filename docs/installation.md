# Installation

**Python 3.10+** is required.

```bash
pip install python-cqrs
```

## Extras (5.0+)

| Extra | Provides |
|-------|----------|
| `pydantic` | `PydanticRequest`, `PydanticResponse`, `Pydantic*Event` |
| `sqlalchemy` | SQLAlchemy outbox + saga storage |
| `kafka` | Kafka broker (`aiokafka`) |
| `rabbit` | AMQP broker |
| `protobuf` | Protobuf serializers |
| `aiobreaker` | Circuit breaker helpers |
| `examples` | FastAPI / FastStream sample stack |

```bash
pip install "python-cqrs[pydantic,sqlalchemy]"
pip install "python-cqrs[kafka]"
```

Dataclass-based `Request` / `Response` / `Event` types are the defaults. See [Migration 4→5](migration/4-to-5.md) for the full breaking-change list.
