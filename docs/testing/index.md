---
title: Testing
description: test_harness runs the real python-cqrs mediators and records what they handled, published, and stored.
---

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

<div class="grid cards" markdown>

-   :material-code-tags: **Command**

    Assert the command on the requests and invocations journals.

    [:octicons-arrow-right-24: Read More](command.md)

-   :material-book-open-page-variant: **Query**

    After a read, the handled, published, and outbox journals are empty.

    [:octicons-arrow-right-24: Read More](query.md)

-   :material-bell-ring: **Domain event**

    Assert the domain event on the handled and invocations journals.

    [:octicons-arrow-right-24: Read More](domain_event.md)

-   :material-message-processing: **Notification**

    Assert the notice on the published journal, including its topic.

    [:octicons-arrow-right-24: Read More](notification.md)

-   :material-sync: **Parallel handlers**

    Assert both handler classes on the invocations journal.

    [:octicons-arrow-right-24: Read More](parallel_handlers.md)

-   :material-wrench: **Handler errors**

    The command result returns from send; the error is on the handler_errors journal.

    [:octicons-arrow-right-24: Read More](handler_errors.md)

-   :material-bell-ring: **Unhandled event**

    Assert the event type on the unhandled journal.

    [:octicons-arrow-right-24: Read More](unhandled_event.md)

-   :material-routes: **Event mediator**

    Assert the handler on the invocations journal, method handle.

    [:octicons-arrow-right-24: Read More](event_mediator.md)

-   :material-backup-restore: **Request fallback**

    Assert both classes on invocations; the requests journal holds the fallback response.

    [:octicons-arrow-right-24: Read More](request_fallback.md)

-   :material-backup-restore: **Event fallback**

    Assert both classes on the invocations journal.

    [:octicons-arrow-right-24: Read More](event_fallback.md)

-   :material-flash: **Circuit breaker**

    An open fake ICircuitBreaker leaves the primary off the invocations journal.

    [:octicons-arrow-right-24: Read More](circuit_breaker.md)

-   :material-filter-variant: **Middleware**

    The middlewares journal records called_next; requests holds the middleware response.

    [:octicons-arrow-right-24: Read More](middleware.md)

-   :material-sitemap: **Scope SEND**

    Assert invocation order on the invocations journal under ScopeStrategy.SEND.

    [:octicons-arrow-right-24: Read More](scope_send.md)

-   :material-sitemap: **Scope HANDLER and NONE**

    Assert both handlers on the invocations journal; order is not checked.

    [:octicons-arrow-right-24: Read More](scope_handler.md)

-   :material-link-variant: **Chain**

    Assert the entered step on the invocations journal.

    [:octicons-arrow-right-24: Read More](chain.md)

-   :material-play-circle: **Streaming**

    Assert values on the yields journal and the event on handled.

    [:octicons-arrow-right-24: Read More](streaming.md)

-   :material-backup-restore: **Streaming fallback**

    Assert both handlers on the yields and invocations journals.

    [:octicons-arrow-right-24: Read More](streaming_fallback.md)

-   :material-sitemap: **Saga step**

    Assert act on the invocations journal and the running saga count.

    [:octicons-arrow-right-24: Read More](saga_step.md)

-   :material-undo: **Saga compensation**

    Assert compensate on the invocations journal and the failed saga status.

    [:octicons-arrow-right-24: Read More](saga_compensation.md)

-   :material-flash: **Saga fallback**

    Assert both classes on the invocations journal; the saga stays completed.

    [:octicons-arrow-right-24: Read More](saga_fallback.md)

-   :material-flash: **Saga circuit breaker**

    A fake ISagaStepCircuitBreaker leaves the primary off the invocations journal.

    [:octicons-arrow-right-24: Read More](saga_circuit_breaker.md)

-   :material-restore: **Saga recovery**

    Recover through the sagas journal; a finished step does not act again.

    [:octicons-arrow-right-24: Read More](saga_recovery.md)

-   :material-database: **Inbox**

    Assert the command on the requests journal and the processed inbox row.

    [:octicons-arrow-right-24: Read More](inbox.md)

-   :material-wrench: **Inbox failure**

    Assert NOT_PROCESSED and flush_counter on the inbox journal.

    [:octicons-arrow-right-24: Read More](inbox_failure.md)

-   :material-database-outline: **Outbox**

    Assert the row on the outbox journal, then the notice on published.

    [:octicons-arrow-right-24: Read More](outbox.md)

-   :material-wrench: **Outbox broker error**

    A broker error leaves the outbox row not produced; the published journal stays empty.

    [:octicons-arrow-right-24: Read More](outbox_broker_error.md)

</div>

## Models

<div class="grid cards" markdown>

-   :material-package-variant: **Dataclass**

    The response is on requests. The harness adds no validator.

    [:octicons-arrow-right-24: Read More](dataclass.md)

-   :material-check-circle: **Pydantic**

    ValidationError is raised by the constructor, before send. A valid send returns the response.

    [:octicons-arrow-right-24: Read More](pydantic.md)

-   :material-code-json: **JSON**

    Default path for a published message. content_type is None.

    [:octicons-arrow-right-24: Read More](json.md)

-   :material-code-braces: **Protobuf**

    Published message content_type and payload_bytes. The harness does not import protobuf.

    [:octicons-arrow-right-24: Read More](protobuf.md)

-   :material-puzzle: **di**

    ScopeStrategy.SEND on di.Container shares one session. Pass di.Container, not TestContainer.

    [:octicons-arrow-right-24: Read More](di.md)

</div>

## Recipes

<div class="grid cards" markdown>

-   :material-web: **FastAPI**

    TestClient and dependency_overrides. Assert requests and outbox. The harness does not import FastAPI.

    [:octicons-arrow-right-24: Read More](fastapi.md)

-   :material-message-processing: **FastStream**

    TestKafkaBroker delivers. The harness checks invocations or the inbox and does not import FastStream.

    [:octicons-arrow-right-24: Read More](faststream.md)

-   :material-database: **SQLAlchemy**

    Session rollback and SqlAlchemyOutboxedEventRepository on SQLite. The harness does not import SQLAlchemy.

    [:octicons-arrow-right-24: Read More](sqlalchemy.md)

-   :material-database: **SQLModel**

    SqlModelOutboxedEventRepository under the sqlmodel marker. The harness does not import SQLModel.

    [:octicons-arrow-right-24: Read More](sqlmodel.md)

-   :material-puzzle: **dishka**

    around wraps a mediator that is already built. The harness does not import dishka.

    [:octicons-arrow-right-24: Read More](dishka.md)

-   :material-puzzle: **dependency-injector**

    around wraps the mediator. The adapter does not implement SupportsScope, so scope_strategy is not SEND.

    [:octicons-arrow-right-24: Read More](dependency_injector.md)

-   :material-message-processing: **Kafka and AMQP**

    The unit test uses CapturingMessageBroker. Real Kafka and AMQP adapters stay in integration tests.

    [:octicons-arrow-right-24: Read More](kafka_amqp.md)

</div>

## Outside the harness

These pages are here so the feature is not dropped. They are not a `test_harness` run.

<div class="grid cards" markdown>

-   :material-graph: **Mermaid**

    CoRMermaid and SagaMermaid draw sequence and class diagrams. They take no part in send.

    [:octicons-arrow-right-24: Read More](mermaid.md)

-   :material-cog: **Compressor**

    ZlibCompressor is checked by the serializer tests. The harness sees payload_bytes as finished bytes.

    [:octicons-arrow-right-24: Read More](compressor.md)

-   :material-database-cog: **Alembic**

    rebind_outbox_model puts the outbox table on the application metadata. It is a migration, not a handler run.

    [:octicons-arrow-right-24: Read More](alembic.md)

-   :material-database: **Transaction log tailing**

    A process that reads the database log. It is not mediator.send and is not run through the harness.

    [:octicons-arrow-right-24: Read More](log_tailing.md)

</div>
