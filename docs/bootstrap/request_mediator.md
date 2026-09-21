# Request Mediator

<div class="grid cards" markdown>

-   :material-home: **Back to Bootstrap Overview**

    Return to the Bootstrap overview page with all configuration options.

    [:octicons-arrow-left-24: Back to Overview](index.md)

-   :material-code-tags: **Commands / Requests Handling**

    Commands, queries, handlers, and request/response mapping.

    [:octicons-arrow-right-24: Read More](../request_handler/index.md)

</div>

## Overview

The `RequestMediator` is the standard mediator for handling commands and queries. It processes requests synchronously and emits events after handler execution.

### Basic Configuration

```python
import di
import cqrs
from cqrs.requests import bootstrap

def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(CreateUserCommand, CreateUserCommandHandler)

def queries_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(GetUserQuery, GetUserQueryHandler)

def events_mapper(mapper: cqrs.EventMap) -> None:
    mapper.bind(
        cqrs.DomainEvent[UserCreatedPayload],
        UserCreatedEventHandler
    )

# Basic bootstrap with di.Container
mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    queries_mapper=queries_mapper,
    domain_events_mapper=events_mapper,
)
```

`RequestMediator(..., scope_strategy=ScopeStrategy.SEND)` and `setup_mediator(..., scope_strategy=ScopeStrategy.SEND)` work out of the box: `concurrent_event_handle_enable` defaults to `None` (`False` under SEND, sequential BFS). Do not pass `concurrent_event_handle_enable=True` with SEND — that raises `ValueError`. `requests.bootstrap` still defaults concurrent processing to `False`. For a shared UoW between command, fallback, and domain events, pass `scope_strategy=ScopeStrategy.SEND` (see [Scope Strategies](../scoped_dependencies/strategies.md)).

```python
from cqrs import ScopeStrategy

mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    domain_events_mapper=events_mapper,
    scope_strategy=ScopeStrategy.SEND,  # sequential events; no concurrent=False needed
)
```

### With Message Broker

```python
from cqrs.message_brokers import devnull, kafka

# Using DevnullMessageBroker (for testing)
mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    domain_events_mapper=events_mapper,
    message_broker=devnull.DevnullMessageBroker(),
)

# Using KafkaMessageBroker
from cqrs.adapters.kafka import KafkaProducerAdapter

kafka_producer = KafkaProducerAdapter(
    bootstrap_servers=["localhost:9092"],
    client_id="my-app",
)

mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    domain_events_mapper=events_mapper,
    message_broker=kafka.KafkaMessageBroker(
        producer=kafka_producer,
        aiokafka_log_level="ERROR",
    ),
)
```

### With Parallel Event Processing

Parallel events require `HANDLER` or `NONE` (the default). SEND infers sequential processing and rejects an explicit `True`.

```python
from cqrs import ScopeStrategy

# Enable parallel event processing (HANDLER / NONE only)
mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    domain_events_mapper=events_mapper,
    scope_strategy=ScopeStrategy.HANDLER,  # or omit for NONE
    max_concurrent_event_handlers=5,  # Process up to 5 events concurrently
    concurrent_event_handle_enable=True,  # Enable parallel processing
)
```

### With Custom Middlewares

```python
from cqrs.middlewares import base

class CustomMiddleware(base.Middleware):
    async def __call__(self, request: cqrs.Request, handle):
        print(f"Before handling {type(request).__name__}")
        result = await handle(request)
        print(f"After handling {type(request).__name__}")
        return result

mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    middlewares=[CustomMiddleware()],
)
```

### With On Startup Callbacks

```python
def initialize_database():
    # Initialize database connections, create tables, etc.
    print("Database initialized")

def setup_cache():
    # Setup cache connections
    print("Cache initialized")

mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    on_startup=[initialize_database, setup_cache],
)
```

### Complete Example

```python
import di
import cqrs
from cqrs.requests import bootstrap
from cqrs.message_brokers import devnull
from cqrs.middlewares import base

class CreateUserCommand(cqrs.Request):
    user_id: str
    email: str

class UserCreatedEvent(cqrs.DomainEvent):
    user_id: str
    email: str

class CreateUserCommandHandler(cqrs.RequestHandler[CreateUserCommand, None]):
    def __init__(self):
        self._events = []

    @property
    def events(self) -> list[cqrs.Event]:
        return self._events

    async def handle(self, request: CreateUserCommand) -> None:
        # Business logic
        self._events.append(
            UserCreatedEvent(user_id=request.user_id, email=request.email)
        )

class UserCreatedEventHandler(cqrs.EventHandler[UserCreatedEvent]):
    async def handle(self, event: UserCreatedEvent) -> None:
        print(f"User {event.user_id} created with email {event.email}")

def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(CreateUserCommand, CreateUserCommandHandler)

def events_mapper(mapper: cqrs.EventMap) -> None:
    mapper.bind(UserCreatedEvent, UserCreatedEventHandler)

# Complete configuration
mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    domain_events_mapper=events_mapper,
    message_broker=devnull.DevnullMessageBroker(),
    max_concurrent_event_handlers=3,
    concurrent_event_handle_enable=True,
    on_startup=[lambda: print("Application started")],
)

# Use the mediator
result = await mediator.send(CreateUserCommand(user_id="1", email="user@example.com"))
```
