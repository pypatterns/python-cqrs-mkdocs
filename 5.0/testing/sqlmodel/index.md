# SQLModel outbox

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

The harness does not import SQLModel. Mark the test `sqlmodel`. Read `outbox` on `SqlModelOutboxedEventRepository`. `published` stays empty until `produce_available`.

See [ORM](https://mkdocs.python-cqrs.dev/latest/orm/index.md).

The `session` fixture is the same as on the [SQLAlchemy](https://mkdocs.python-cqrs.dev/latest/testing/sqlalchemy/index.md) page, with `sqlmodel.ext.asyncio.session.AsyncSession`.

```python
pytestmark = pytest.mark.sqlmodel

async def test_send_stores_a_pending_row(session: AsyncSession) -> None:
    event_map = cqrs.OutboxedEventMap()
    event_map.register("order_created", OrderCreatedNotice)
    outbox = cqrs.outbox.sqlmodel.SqlModelOutboxedEventRepository(session, event_map=event_map)
    container = di.Container()
    bind_outbox(container, outbox)
    mediator = bootstrap.bootstrap(di_container=container, commands_mapper=commands_mapper)
    async with test_harness.around(mediator, outbox=outbox) as harness:
        await mediator.send(CreateOrder(sku="book"))

        assert harness.outbox.pending_count == 1
```

Library example: [`examples/testing/test_sqlmodel_outbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_sqlmodel_outbox.py).
