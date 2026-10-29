# Outbox

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

The row is on `outbox`. `published` stays empty until `produce_available`. After that call, the status is produced and the notice is on `published`.

See [Transactional Outbox](https://mkdocs.python-cqrs.dev/latest/outbox/index.md).

Transaction log tailing is a different process, not this page; see [Transaction log tailing](https://mkdocs.python-cqrs.dev/latest/testing/log_tailing/index.md).

The harness creates `harness.outbox_repository` and does not bind it. Arrange binds it into the container, so the handler receives it as `cqrs.OutboxedEventRepository`. Sending and producing are two actions, so they are two tests.

```python
class CreateOrderHandler(cqrs.RequestHandler[CreateOrder]):
    def __init__(self, repository: cqrs.OutboxedEventRepository) -> None:
        self._repository = repository

    async def handle(self, request: CreateOrder):
        self._repository.add(OrderCreatedNotice(payload={"order_id": "1"}))
        return CreatedOrder(order_id="1")

def bind_outbox(container: di.Container, repository: cqrs.OutboxedEventRepository) -> None:
    def outbox_repository() -> cqrs.OutboxedEventRepository:
        return repository

    container.bind(
        di.bind_by_type(
            di.dependent.Dependent(outbox_repository, scope="request"),
            cqrs.OutboxedEventRepository,
        ),
    )

async def test_outbox_holds_the_row_until_produce() -> None:
    container = di.Container()
    async with test_harness(container, commands_mapper=commands_mapper) as harness:
        bind_outbox(container, harness.outbox_repository)

        await harness.mediator.send(CreateOrder(sku="book"))

        assert harness.outbox.pending_count == 1
        harness.published.assert_empty()

async def test_outbox_produce_publishes_the_row() -> None:
    container = di.Container()
    async with test_harness(container, commands_mapper=commands_mapper) as harness:
        bind_outbox(container, harness.outbox_repository)
        await harness.mediator.send(CreateOrder(sku="book"))

        await harness.outbox.produce_available()

        assert harness.outbox.produced_count == 1
        harness.published.assert_one(OrderCreatedNotice, topic="order_events")
```

Library example: [`examples/testing/test_outbox_inbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_outbox_inbox.py).
