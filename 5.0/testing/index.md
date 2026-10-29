# Testing

`test_harness` runs the mediators the application already uses and records what they did. It does not add a bus. Commands and queries stay `cqrs.Request`. Import it from `cqrs.testing`. It is not in `cqrs.__all__`.

Two entries return the same harness. Building a stand takes the same mapper and middleware arguments as bootstrap. The builder passes `compensation_retry_delay=0` unless the test passes a delay. `around` does not change the delay of a mediator that is already built.

Every example on these pages is a pytest test written as Arrange, Act, Assert. Arrange builds the container, the mappers, and the harness. Act is one call: `send`, `stream`, `execute`, `process_available`, or `produce_available`. Assert reads the journals. Setup that a test needs but does not check, such as a database session, goes into a fixture. The test functions are `async def`, so run them with `pytest-asyncio` and `asyncio_mode = auto`.

```python
import di

import cqrs
from cqrs.testing import test_harness

async def test_create_order() -> None:
    container = di.Container()
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
        result = await harness.mediator.send(CreateOrder(sku="book"))

        assert result.order_id == "1"
        assert harness.requests.contains(CreateOrder)
```

`around` wraps mediators the application already built. For the block it wraps resolve, the broker, saga storage, and the listener, and puts them back in `finally`.

```python
async def test_create_order_on_the_application_mediator() -> None:
    async with test_harness.around(
        mediator,
        event_mediator=event_mediator,
        streaming_mediator=streaming_mediator,
        saga_mediator=saga_mediator,
        outbox=outbox,
        inbox=inbox,
    ) as harness:
        await mediator.send(CreateOrder(sku="book"))

        harness.invocations.assert_entered(CreateOrderHandler)
```

The library keeps each page's test in [`examples/testing/`](https://github.com/vadikko2/python-cqrs/tree/master/examples/testing). Run them with `pytest -c tests/pytest-config.ini --rootdir=. examples/testing`.

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

- **Command**

  Assert the command on the requests and invocations journals.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/command/index.md)

- **Query**

  After a read, the handled, published, and outbox journals are empty.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/query/index.md)

- **Domain event**

  Assert the domain event on the handled and invocations journals.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/domain_event/index.md)

- **Notification**

  Assert the notice on the published journal, including its topic.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/notification/index.md)

- **Parallel handlers**

  Assert both handler classes on the invocations journal.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/parallel_handlers/index.md)

- **Handler errors**

  The command result returns from send; the error is on the handler_errors journal.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/handler_errors/index.md)

- **Unhandled event**

  Assert the event type on the unhandled journal.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/unhandled_event/index.md)

- **Event mediator**

  Assert the handler on the invocations journal, method handle.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/event_mediator/index.md)

- **Request fallback**

  Assert both classes on invocations; the requests journal holds the fallback response.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/request_fallback/index.md)

- **Event fallback**

  Assert both classes on the invocations journal.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/event_fallback/index.md)

- **Circuit breaker**

  An open fake ICircuitBreaker leaves the primary off the invocations journal.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/circuit_breaker/index.md)

- **Middleware**

  The middlewares journal records called_next; requests holds the middleware response.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/middleware/index.md)

- **Scope SEND**

  Assert invocation order on the invocations journal under ScopeStrategy.SEND.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/scope_send/index.md)

- **Scope HANDLER and NONE**

  Assert both handlers on the invocations journal; order is not checked.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/scope_handler/index.md)

- **Chain**

  Assert the entered step on the invocations journal.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/chain/index.md)

- **Streaming**

  Assert values on the yields journal and the event on handled.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/streaming/index.md)

- **Streaming fallback**

  Assert both handlers on the yields and invocations journals.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/streaming_fallback/index.md)

- **Saga step**

  Assert act on the invocations journal and the running saga count.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/saga_step/index.md)

- **Saga compensation**

  Assert compensate on the invocations journal and the failed saga status.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/saga_compensation/index.md)

- **Saga fallback**

  Assert both classes on the invocations journal; the saga stays completed.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/saga_fallback/index.md)

- **Saga circuit breaker**

  A fake ISagaStepCircuitBreaker leaves the primary off the invocations journal.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/saga_circuit_breaker/index.md)

- **Saga recovery**

  Recover through the sagas journal; a finished step does not act again.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/saga_recovery/index.md)

- **Inbox**

  Assert the command on the requests journal and the processed inbox row.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/inbox/index.md)

- **Inbox failure**

  Assert NOT_PROCESSED and flush_counter on the inbox journal.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/inbox_failure/index.md)

- **Outbox**

  Assert the row on the outbox journal, then the notice on published.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/outbox/index.md)

- **Outbox broker error**

  A broker error leaves the outbox row not produced; the published journal stays empty.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/outbox_broker_error/index.md)

## Models

- **Dataclass**

  The response is on requests. The harness adds no validator.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/dataclass/index.md)

- **Pydantic**

  ValidationError is raised by the constructor, before send. A valid send returns the response.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/pydantic/index.md)

- **JSON**

  Default path for a published message. content_type is None.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/json/index.md)

- **Protobuf**

  Published message content_type and payload_bytes. The harness does not import protobuf.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/protobuf/index.md)

- **di**

  ScopeStrategy.SEND on di.Container shares one session. Pass di.Container, not TestContainer.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/di/index.md)

## Recipes

- **FastAPI**

  TestClient and dependency_overrides. Assert requests and outbox. The harness does not import FastAPI.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/fastapi/index.md)

- **FastStream**

  TestKafkaBroker delivers. The harness checks invocations or the inbox and does not import FastStream.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/faststream/index.md)

- **SQLAlchemy**

  Session rollback and SqlAlchemyOutboxedEventRepository on SQLite. The harness does not import SQLAlchemy.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/sqlalchemy/index.md)

- **SQLModel**

  SqlModelOutboxedEventRepository under the sqlmodel marker. The harness does not import SQLModel.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/sqlmodel/index.md)

- **dishka**

  around wraps a mediator that is already built. The harness does not import dishka.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/dishka/index.md)

- **dependency-injector**

  around wraps the mediator. The adapter does not implement SupportsScope, so scope_strategy is not SEND.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/dependency_injector/index.md)

- **Kafka and AMQP**

  The unit test uses CapturingMessageBroker. Real Kafka and AMQP adapters stay in integration tests.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/kafka_amqp/index.md)

## Outside the harness

These pages are here so the feature is not dropped. They are not a `test_harness` run.

- **Mermaid**

  CoRMermaid and SagaMermaid draw sequence and class diagrams. They take no part in send.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/mermaid/index.md)

- **Compressor**

  ZlibCompressor is checked by the serializer tests. The harness sees payload_bytes as finished bytes.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/compressor/index.md)

- **Alembic**

  rebind_outbox_model puts the outbox table on the application metadata. It is a migration, not a handler run.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/alembic/index.md)

- **Transaction log tailing**

  A process that reads the database log. It is not mediator.send and is not run through the harness.

  [Read More](https://mkdocs.python-cqrs.dev/latest/testing/log_tailing/index.md)
