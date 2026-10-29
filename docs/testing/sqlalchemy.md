---
title: SQLAlchemy outbox
description: Session rollback and SqlAlchemyOutboxedEventRepository on SQLite. The harness does not import SQLAlchemy.
---

# SQLAlchemy outbox

The harness does not import SQLAlchemy. The session rolls back. `SqlAlchemyOutboxedEventRepository` runs on SQLite through `aiosqlite`, with no Docker. Mark the test `sqlalchemy`. Read `outbox`: `produce_available` works with that repository, and the pending count stays empty once the row is produced.

See [ORM](../orm.md).

```python
async with engine.begin() as connection:
    session = AsyncSession(bind=connection)
    outbox = cqrs.SqlAlchemyOutboxedEventRepository(session, event_map=event_map)
    async with test_harness.around(mediator, outbox=outbox) as harness:
        await mediator.send(CreateOrder(sku="book"))
        await harness.outbox.produce_available()
        assert harness.outbox.produced_count == 1
    await connection.rollback()
```

Library example: [`examples/testing/sqlalchemy_outbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/sqlalchemy_outbox.py).
