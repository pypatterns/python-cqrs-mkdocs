---
title: SQLModel support
description: Optional SQLModel outbox and saga storage with the same behavior as the SQLAlchemy implementations.
---

# SQLModel

From **python-cqrs 5.1** the transactional outbox and saga storage can use either SQLAlchemy or SQLModel. Both cover the same operations and render the same DDL, including the dialect-aware column types documented in [Outbox database support](outbox/databases.md).

Install one extra and import the matching module:

```bash
pip install "python-cqrs[sqlalchemy]"   # SqlAlchemyOutboxedEventRepository, SqlAlchemySagaStorage
pip install "python-cqrs[sqlmodel]"     # SqlModelOutboxedEventRepository, SqlModelSagaStorage
```

`sqlmodel` pulls in SQLAlchemy. The SQLModel classes are thin models over that same schema: batch reads, flush budget, status ordering, codecs, compression, checkpoint runs, optimistic locking, and recovery queries behave the same way.

Use one ORM for these tables in a process. The SQLModel models live on their own metadata (`Base` in `cqrs.outbox.sqlmodel` and `cqrs.saga.storage.sqlmodel` is the same base), not on your application's `SQLModel.metadata`.

## Outbox

```python
from sqlalchemy.ext.asyncio import create_async_engine
from sqlmodel.ext.asyncio.session import AsyncSession

from cqrs.outbox.sqlmodel import Base, SqlModelOutboxedEventRepository

engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")

async with engine.begin() as connection:
    await connection.run_sync(Base.metadata.create_all)

async with AsyncSession(engine) as session:
    repository = SqlModelOutboxedEventRepository(session)
    repository.add(event)
    await repository.commit()
    batch = await repository.get_many(batch_size=100)
```

`SqlModelOutboxedEventRepository` accepts the same `compressor`, `serializer`, and `event_map` arguments as `SqlAlchemyOutboxedEventRepository`.

To attach the outbox table to your own SQLModel base (for example so Alembic sees it next to application tables), call `rebind_outbox_model` from `cqrs.outbox.sqlmodel`. On PostgreSQL the unique constraint name `event_id_unique_index` must stay unique in the schema, so drop or rename the previous outbox table before creating the rebound one.

## Saga storage

Pass an `async_sessionmaker` whose class is SQLModel's async session:

```python
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlmodel.ext.asyncio.session import AsyncSession

from cqrs.saga.storage.sqlmodel import Base, SqlModelSagaStorage

engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")
session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async with engine.begin() as connection:
    await connection.run_sync(Base.metadata.create_all)

storage = SqlModelSagaStorage(session_factory)
```

`SqlModelSagaStorage` implements the full saga storage interface, including `create_run()` for checkpoint commits and `load_saga_state(..., read_for_update=True)`. Hand it to `SagaMediator` the same way as `SqlAlchemySagaStorage`.

Table names follow the SQLAlchemy storage: `saga_executions` and `saga_logs`, or the `CQRS_SAGA_EXECUTION_TABLE_NAME` and `CQRS_SAGA_LOG_TABLE_NAME` environment variables read when the SQLAlchemy storage module is imported.

## Schema

MySQL, MariaDB, and PostgreSQL are the supported production databases. The SQLModel models compile to the same `CREATE TABLE` statements as the SQLAlchemy models, so an existing SQLAlchemy deployment does not need a migration to be read by the SQLModel repository, and the other way around. See [Database support](outbox/databases.md) for dialect types, Alembic, and `register_dialect()`.
