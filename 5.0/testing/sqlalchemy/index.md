# SQLAlchemy outbox

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

The harness does not import SQLAlchemy. The session rolls back. `SqlAlchemyOutboxedEventRepository` runs on SQLite through `aiosqlite`, with no Docker. Mark the test `sqlalchemy`. Read `outbox`: `produce_available` works with that repository, and the pending count stays empty once the row is produced.

See [ORM](https://mkdocs.python-cqrs.dev/latest/orm/index.md).

The fixture owns the engine, the table, and the rollback, so the test body is only Arrange, Act, and Assert.

```python
pytestmark = pytest.mark.sqlalchemy

@pytest.fixture
async def session() -> typing.AsyncIterator[AsyncSession]:
    engine = create_async_engine("sqlite+aiosqlite://")
    async with engine.begin() as connection:
        await connection.run_sync(_create_sqlite_outbox_table)
        yield AsyncSession(bind=connection)
        await connection.rollback()
    await engine.dispose()

async def test_produce_publishes_the_stored_row(session: AsyncSession) -> None:
    event_map = cqrs.OutboxedEventMap()
    event_map.register("order_created", OrderCreatedNotice)
    outbox = cqrs.SqlAlchemyOutboxedEventRepository(session, event_map=event_map)
    container = di.Container()
    bind_outbox(container, outbox)
    mediator = bootstrap.bootstrap(di_container=container, commands_mapper=commands_mapper)
    async with test_harness.around(mediator, outbox=outbox) as harness:
        await mediator.send(CreateOrder(sku="book"))

        await harness.outbox.produce_available()

        assert harness.outbox.produced_count == 1
```

Library example: [`examples/testing/test_sqlalchemy_outbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_sqlalchemy_outbox.py).
