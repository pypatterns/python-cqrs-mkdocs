# Installation

**Python 3.10+** is required (tested on 3.10–3.15).

```bash
pip install python-cqrs
```

## Extras (5.0+)

| Extra | Provides |
|-------|----------|
| `pydantic` | `PydanticRequest`, `PydanticResponse`, `Pydantic*Event` |
| `sqlalchemy` | SQLAlchemy outbox + saga storage |
| `sqlmodel` | SQLModel outbox + saga storage (same behavior as SQLAlchemy; 5.1+) |
| `kafka` | Kafka broker (`aiokafka`) |
| `rabbit` | AMQP broker |
| `protobuf` | Protobuf serializers |
| `aiobreaker` | Circuit breaker helpers |
| `di` | `di` container. Bootstrap wraps `di.Container`. Needed for `ScopeStrategy.SEND` |
| `dependency-injector` | `DependencyInjectorCQRSContainer` |
| `dishka` | `DishkaCQRSContainer` |
| `examples` | FastAPI / FastStream sample stack |

!!! warning "Breaking change in 5.6.0"
    These pages match **5.6.0**. `pip install python-cqrs` no longer installs `di` or `dependency-injector`. Install `"python-cqrs[di]"` or `"python-cqrs[dependency-injector]"`. On 5.5.0, `bootstrap` still requires `di_container`. Publish this site with the 5.6.0 release.

The base install does not include a DI library. Omit `di_container` and bootstrap uses `cqrs.SimpleContainer`, which constructs handlers that take no constructor arguments. `SimpleContainer.register` pins an instance when a handler needs one, and every `resolve` returns that same instance. Install `di`, `dependency-injector`, or `dishka` when handlers should be built by that container.

```bash
pip install "python-cqrs[pydantic,sqlalchemy]"
pip install "python-cqrs[sqlmodel]"
pip install "python-cqrs[kafka]"
```

Dataclass-based `Request` / `Response` / `Event` types are the defaults. See [Migration 4→5](migration/4-to-5.md) for the full breaking-change list. Outbox and saga storage with SQLAlchemy or SQLModel is described in [ORM](orm.md).
