---
title: Testing
description: test_harness runs the real python-cqrs mediators and records what they handled, published, and stored.
---

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

- [Command](command.md)
- [Query](query.md)
- [Domain event](domain_event.md)
- [Notification](notification.md)
- [Parallel handlers](parallel_handlers.md)
- [Swallowed handler error](handler_errors.md)
- [Unhandled event](unhandled_event.md)
- [Event mediator](event_mediator.md)
- [Request fallback](request_fallback.md)
- [Event fallback](event_fallback.md)
- [Circuit breaker](circuit_breaker.md)
- [Middleware](middleware.md)
- [ScopeStrategy.SEND](scope_send.md)
- [ScopeStrategy.HANDLER and NONE](scope_handler.md)
- [Chain](chain.md)
- [Stream](streaming.md)
- [Streaming fallback](streaming_fallback.md)
- [Saga step](saga_step.md)
- [Compensation](saga_compensation.md)
- [Saga fallback](saga_fallback.md)
- [Saga circuit breaker](saga_circuit_breaker.md)
- [Saga recovery](saga_recovery.md)
- [Inbox](inbox.md)
- [Inbox handler error](inbox_failure.md)
- [Outbox](outbox.md)
- [Outbox broker error](outbox_broker_error.md)

## Models

- [Dataclass](dataclass.md)
- [Pydantic](pydantic.md)
- [JSON](json.md)
- [Protobuf](protobuf.md)
- [di.Container](di.md)

## Recipes

- [FastAPI](fastapi.md)
- [FastStream](faststream.md)
- [SQLAlchemy](sqlalchemy.md)
- [SQLModel](sqlmodel.md)
- [dishka](dishka.md)
- [dependency-injector](dependency_injector.md)
- [Kafka and AMQP](kafka_amqp.md)

## Outside the harness

These pages are here so the feature is not dropped. They are not a `test_harness` run.

- [Mermaid](mermaid.md)
- [Compressor](compressor.md)
- [Alembic](alembic.md)
- [Transaction log tailing](log_tailing.md)
