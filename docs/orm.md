---
title: ORM storage
description: SQLAlchemy and SQLModel storage for the transactional outbox and saga state. Same operations, same DDL.
---

# ORM

The transactional outbox and saga storage can use **SQLAlchemy** or **SQLModel**. Both extras cover the same operations and render the same DDL, including the dialect-aware column types in [Database support](outbox/databases.md).

Use one ORM for these tables in a process.

<div class="grid cards" markdown>

-   :material-database: **SQLAlchemy**

    `SqlAlchemyOutboxedEventRepository` and `SqlAlchemySagaStorage`.

    [:octicons-arrow-right-24: SQLAlchemy](#sqlalchemy)

-   :material-database-cog: **SQLModel**

    Same outbox and saga storage, implemented as SQLModel models. Available since 5.1.

    [:octicons-arrow-right-24: SQLModel](#sqlmodel)

-   :material-code-tags: **Transactional Outbox**

    Batch reads, flush budget, codecs, and `rebind_outbox_model`.

    [:octicons-arrow-right-24: Implementation](outbox/implementation.md)

-   :material-sitemap: **Saga storage**

    Checkpoint runs, optimistic locking, and recovery queries.

    [:octicons-arrow-right-24: Saga storage](saga/storage.md)

</div>

## Install

```bash
pip install "python-cqrs[sqlalchemy]"   # SqlAlchemyOutboxedEventRepository, SqlAlchemySagaStorage
pip install "python-cqrs[sqlmodel]"     # SqlModelOutboxedEventRepository, SqlModelSagaStorage
```

`sqlmodel` pulls in SQLAlchemy. The SQLModel classes are models over that same schema: batch reads, flush budget, status ordering, codecs, compression, checkpoint runs, optimistic locking, and recovery queries behave the same way.

| | SQLAlchemy | SQLModel |
|---|---|---|
| Extra | `python-cqrs[sqlalchemy]` | `python-cqrs[sqlmodel]` |
| Outbox | `cqrs.SqlAlchemyOutboxedEventRepository` | `cqrs.outbox.sqlmodel.SqlModelOutboxedEventRepository` |
| Saga | `cqrs.saga.storage.sqlalchemy.SqlAlchemySagaStorage` | `cqrs.saga.storage.sqlmodel.SqlModelSagaStorage` |
| Session | `sqlalchemy.ext.asyncio.AsyncSession` | `sqlmodel.ext.asyncio.session.AsyncSession` |
| Since | 5.0 (optional extra) | 5.1 |

## SQLAlchemy

Create the tables from `Base.metadata` and pass a SQLAlchemy async session to the outbox repository. Saga storage takes an `async_sessionmaker`, not a single session.

```python
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from cqrs import SqlAlchemyOutboxedEventRepository
from cqrs.outbox.sqlalchemy import Base as OutboxBase
from cqrs.saga.storage.sqlalchemy import Base as SagaBase
from cqrs.saga.storage.sqlalchemy import SqlAlchemySagaStorage

engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")
session_factory = async_sessionmaker(engine, expire_on_commit=False)

async with engine.begin() as connection:
    await connection.run_sync(OutboxBase.metadata.create_all)
    await connection.run_sync(SagaBase.metadata.create_all)

async with session_factory() as session:
    repository = SqlAlchemyOutboxedEventRepository(session)
    repository.add(event)
    await repository.commit()

storage = SqlAlchemySagaStorage(session_factory)
```

Outbox details, including compression, codecs, and `rebind_outbox_model`, are in [Implementation](outbox/implementation.md). Saga checkpoints, optimistic locking, and recovery are in [Saga storage](saga/storage.md#sqlalchemy-storage).

## SQLModel

The SQLModel models live on their own metadata (`Base` in `cqrs.outbox.sqlmodel` and `cqrs.saga.storage.sqlmodel` is the same base), not on your application's `SQLModel.metadata`.

### Outbox

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

### Saga storage

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
