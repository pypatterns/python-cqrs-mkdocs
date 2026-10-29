# Testing

`test_harness` runs the mediators the application already uses and records what they did. It does not add a bus. Commands and queries stay `cqrs.Request`. Import it from `cqrs.testing`. It is not in `cqrs.__all__`.

Two entries return the same harness. Building a stand takes the same mapper and middleware arguments as bootstrap. The builder passes `compensation_retry_delay=0` unless the test passes a delay. `around` does not change the delay of a mediator that is already built.

```python
from cqrs.testing import test_harness

async with test_harness(
    container,
    commands_mapper=commands_mapper,
    queries_mapper=queries_mapper,
    domain_events_mapper=domain_events_mapper,
    events_mapper=events_mapper,
    streaming_mapper=streaming_mapper,
    sagas_mapper=sagas_mapper,
    middlewares=middlewares,
    scope_strategy=cqrs.ScopeStrategy.NONE,
) as harness:
    await harness.mediator.send(CreateOrder(sku="book"))
```

`around` wraps mediators the application already built. For the block it wraps resolve, the broker, saga storage, and the listener, and puts them back in `finally`.

```python
async with test_harness.around(
    mediator,
    event_mediator=event_mediator,
    streaming_mediator=streaming_mediator,
    saga_mediator=saga_mediator,
    outbox=outbox,
    inbox=inbox,
) as harness:
    await mediator.send(CreateOrder(sku="book"))
```

`test_harness(...)` creates a memory outbox and a memory inbox and stores them on `harness.outbox_repository` and `harness.inbox_repository`. It does not bind those ports. The test binds the port.

`TestContainer` is `register(type, instance)` and `async resolve`. For `ScopeStrategy.SEND`, pass `di.Container`, not `TestContainer`.

If the mediator holds `DevnullMessageBroker`, the harness replaces it with `CapturingMessageBroker` for the block and restores it afterwards. Do not read `DevnullMessageBroker.MESSAGE_BUS`.

`contains` is a boolean. `assert_contains`, `assert_one`, and `assert_empty` raise `AssertionError` and list what was recorded. There is no pytest plugin. The same calls work under unittest.

An invocation record has `handler`, `method` (`handle`, `act`, or `compensate`), `argument`, `argument_type`, and `handler_instance`.

## Journals

Three delivery channels stay separate. A test that asks `published` for a domain event gets a miss.

- `invocations` records entry into `handle`, `act`, and `compensate`: the class, the method, and the argument. A chain step, a fallback, a saga step, and an `EventMediator` handler are here. `EventMediator` goes through `EventDispatcher`, not `EventEmitter`, so the emitter listener does not see it.
- `handled` is a `DomainEvent` that `EventEmitter` gave to handlers after a command, a stream, or a saga step.
- `published` is a message that reached `MessageBroker.send_message`. That is a direct `NotificationEvent`, and later `EventProducer`.
- `outbox` is a row the handler stored. It is not in `published` until `produce_available`.
- `requests` is each `send`: the request type, and the response or the exception. A command and a query are both `cqrs.Request`.
- `yields` is what a stream yielded, in order.
- `middlewares` records which middleware saw the request and whether it called `handle`.
- `handler_errors` is a domain-handler error that `send` swallows and logs.
- `unhandled` is a domain event whose map is empty.
- `sagas` is status, context, and step history from storage.
- `inbox` is insert, a duplicate, and processing through `InboxProcessor`.

`assert harness.published.contains(OrderCreated)` is false for a domain event. `assert_contains` says the type is on `handled` or `invocations` and did not go to the broker.

## Handlers

- [Command](https://mkdocs.python-cqrs.dev/latest/testing/command/index.md)
- [Query](https://mkdocs.python-cqrs.dev/latest/testing/query/index.md)
- [Domain event](https://mkdocs.python-cqrs.dev/latest/testing/domain_event/index.md)
- [Notification](https://mkdocs.python-cqrs.dev/latest/testing/notification/index.md)
- [Parallel handlers](https://mkdocs.python-cqrs.dev/latest/testing/parallel_handlers/index.md)
- [Swallowed handler error](https://mkdocs.python-cqrs.dev/latest/testing/handler_errors/index.md)
- [Unhandled event](https://mkdocs.python-cqrs.dev/latest/testing/unhandled_event/index.md)
- [Event mediator](https://mkdocs.python-cqrs.dev/latest/testing/event_mediator/index.md)
- [Request fallback](https://mkdocs.python-cqrs.dev/latest/testing/request_fallback/index.md)
- [Event fallback](https://mkdocs.python-cqrs.dev/latest/testing/event_fallback/index.md)
- [Circuit breaker](https://mkdocs.python-cqrs.dev/latest/testing/circuit_breaker/index.md)
- [Middleware](https://mkdocs.python-cqrs.dev/latest/testing/middleware/index.md)
- [ScopeStrategy.SEND](https://mkdocs.python-cqrs.dev/latest/testing/scope_send/index.md)
- [ScopeStrategy.HANDLER and NONE](https://mkdocs.python-cqrs.dev/latest/testing/scope_handler/index.md)
- [Chain](https://mkdocs.python-cqrs.dev/latest/testing/chain/index.md)
- [Stream](https://mkdocs.python-cqrs.dev/latest/testing/streaming/index.md)
- [Streaming fallback](https://mkdocs.python-cqrs.dev/latest/testing/streaming_fallback/index.md)
- [Saga step](https://mkdocs.python-cqrs.dev/latest/testing/saga_step/index.md)
- [Compensation](https://mkdocs.python-cqrs.dev/latest/testing/saga_compensation/index.md)
- [Saga fallback](https://mkdocs.python-cqrs.dev/latest/testing/saga_fallback/index.md)
- [Saga circuit breaker](https://mkdocs.python-cqrs.dev/latest/testing/saga_circuit_breaker/index.md)
- [Saga recovery](https://mkdocs.python-cqrs.dev/latest/testing/saga_recovery/index.md)
- [Inbox](https://mkdocs.python-cqrs.dev/latest/testing/inbox/index.md)
- [Inbox handler error](https://mkdocs.python-cqrs.dev/latest/testing/inbox_failure/index.md)
- [Outbox](https://mkdocs.python-cqrs.dev/latest/testing/outbox/index.md)
- [Outbox broker error](https://mkdocs.python-cqrs.dev/latest/testing/outbox_broker_error/index.md)

## Models

- [Dataclass](https://mkdocs.python-cqrs.dev/latest/testing/dataclass/index.md)
- [Pydantic](https://mkdocs.python-cqrs.dev/latest/testing/pydantic/index.md)
- [JSON](https://mkdocs.python-cqrs.dev/latest/testing/json/index.md)
- [Protobuf](https://mkdocs.python-cqrs.dev/latest/testing/protobuf/index.md)
- [di.Container](https://mkdocs.python-cqrs.dev/latest/testing/di/index.md)

## Recipes

- [FastAPI](https://mkdocs.python-cqrs.dev/latest/testing/fastapi/index.md)
- [FastStream](https://mkdocs.python-cqrs.dev/latest/testing/faststream/index.md)
- [SQLAlchemy](https://mkdocs.python-cqrs.dev/latest/testing/sqlalchemy/index.md)
- [SQLModel](https://mkdocs.python-cqrs.dev/latest/testing/sqlmodel/index.md)
- [dishka](https://mkdocs.python-cqrs.dev/latest/testing/dishka/index.md)
- [dependency-injector](https://mkdocs.python-cqrs.dev/latest/testing/dependency_injector/index.md)
- [Kafka and AMQP](https://mkdocs.python-cqrs.dev/latest/testing/kafka_amqp/index.md)

## Outside the harness

These pages are here so the feature is not dropped. They are not a `test_harness` run.

- [Mermaid](https://mkdocs.python-cqrs.dev/latest/testing/mermaid/index.md)
- [Compressor](https://mkdocs.python-cqrs.dev/latest/testing/compressor/index.md)
- [Alembic](https://mkdocs.python-cqrs.dev/latest/testing/alembic/index.md)
- [Transaction log tailing](https://mkdocs.python-cqrs.dev/latest/testing/log_tailing/index.md)
