---
title: Scoped Dependencies Tutorial
description: Share one SQLAlchemy AsyncSession across a command, a domain event, and the transactional outbox under ScopeStrategy.SEND.
---

# Tutorial: one session for command, event, and outbox

<div class="grid cards" markdown>

-   :material-home: **Back to Scoped Dependencies Overview**

    Return to the Scoped Dependencies overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

---

This is the page to copy. One `mediator.send()` under `ScopeStrategy.SEND` keeps a **single** SQLAlchemy `AsyncSession` for:

1. the command handler (business row + outbox row)
2. the domain-event handler (audit row)
3. `SqlAlchemyOutboxedEventRepository` built from **that same session**

The generator commits **after** both handlers finish, so all three writes are one transaction. SQLite is enough; you do not need Postgres to learn this.

!!! warning "Do not call `session_factory()` in the outbox bind"
    `lambda: SqlAlchemyOutboxedEventRepository(session=session_factory())` opens a **new** session on every `resolve()`. The command and the event would not share a transaction, and the scoped generator would not own that session. Bind `AsyncSession` as a generator, then `outbox_from_session(session)`.

!!! note "di scope=request is not enough"
    That flag is provider lifetime inside `di`. python-cqrs only keeps the generator open when you pass `scope_strategy=ScopeStrategy.SEND` (or wrap several `send()` calls in `enter_scope` — [Advanced](advanced.md)).

Runnable file: [`examples/di/scoped_dependencies_sqlalchemy.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/di/scoped_dependencies_sqlalchemy.py) (`pip install -e ".[examples]"` for `aiosqlite`).

```python
from __future__ import annotations

import asyncio
import typing

import di
import pydantic
from di import dependent
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy.pool import StaticPool

import cqrs
from cqrs.requests import bootstrap


class Base(DeclarativeBase):
    pass


class TaskRow(Base):
    __tablename__ = "tasks"
    id: Mapped[int] = mapped_column(primary_key=True)
    cancelled: Mapped[bool] = mapped_column(default=False)


class AuditRow(Base):
    __tablename__ = "audit"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    task_id: Mapped[int]
    note: Mapped[str]


def _create_sqlite_outbox_table(sync_connection: typing.Any) -> None:
    # OutboxModel.id uses Identity(); SQLite needs AUTOINCREMENT. Same helper as fastapi_outbox.
    sync_connection.exec_driver_sql(
        """
        CREATE TABLE IF NOT EXISTS outbox (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id BLOB NOT NULL,
            event_id_bin BLOB NOT NULL,
            event_status VARCHAR(12) NOT NULL,
            flush_counter SMALLINT NOT NULL DEFAULT 0,
            event_name VARCHAR(255) NOT NULL,
            topic VARCHAR(255) NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
            payload BLOB NOT NULL,
            CONSTRAINT event_id_unique_index UNIQUE (event_id_bin, event_name)
        )
        """,
    )


engine = create_async_engine(
    "sqlite+aiosqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False)


async def init_schema() -> None:
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
        await connection.run_sync(_create_sqlite_outbox_table)


async def session_provider() -> typing.AsyncIterator[AsyncSession]:
    session = SessionLocal()
    try:
        yield session
        await session.commit()  # after command + domain events
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()


def outbox_from_session(
    session: AsyncSession,
) -> cqrs.SqlAlchemyOutboxedEventRepository:
    return cqrs.SqlAlchemyOutboxedEventRepository(session)


class TaskCancelledPayload(pydantic.BaseModel, frozen=True):
    task_id: int


cqrs.OutboxedEventMap.register(
    "scoped_task_cancelled",
    cqrs.NotificationEvent[TaskCancelledPayload],
)


class CancelTask(cqrs.Request):
    task_id: int


class TaskCancelled(cqrs.DomainEvent, frozen=True):
    task_id: int


class CancelTaskHandler(cqrs.RequestHandler[CancelTask, None]):
    def __init__(
        self,
        session: AsyncSession,
        outbox: cqrs.OutboxedEventRepository,
    ) -> None:
        self._session = session
        self._outbox = outbox
        self._events: list[cqrs.Event] = []

    @property
    def events(self) -> typing.List[cqrs.Event]:
        return self._events

    async def handle(self, request: CancelTask) -> None:
        self._session.add(TaskRow(id=request.task_id, cancelled=True))
        self._outbox.add(
            cqrs.NotificationEvent[TaskCancelledPayload](
                event_name="scoped_task_cancelled",
                topic="tasks",
                payload=TaskCancelledPayload(task_id=request.task_id),
            ),
        )
        # Do not call outbox.commit() here — that would commit before the event handler.
        self._events.append(TaskCancelled(task_id=request.task_id))


class TaskCancelledHandler(cqrs.EventHandler[TaskCancelled]):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def handle(self, event: TaskCancelled) -> None:
        self._session.add(AuditRow(task_id=event.task_id, note="cancelled"))


def setup_di() -> di.Container:
    container = di.Container()
    container.bind(
        di.bind_by_type(
            dependent.Dependent(session_provider, scope="request"),
            AsyncSession,
        ),
    )
    container.bind(
        di.bind_by_type(
            dependent.Dependent(outbox_from_session, scope="request"),
            cqrs.OutboxedEventRepository,
        ),
    )
    return container


def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(CancelTask, CancelTaskHandler)


def events_mapper(mapper: cqrs.EventMap) -> None:
    mapper.bind(TaskCancelled, TaskCancelledHandler)


async def main() -> None:
    await init_schema()
    mediator = bootstrap.bootstrap(
        di_container=setup_di(),
        commands_mapper=commands_mapper,
        domain_events_mapper=events_mapper,
        scope_strategy=cqrs.ScopeStrategy.SEND,
    )
    await mediator.send(CancelTask(task_id=7))

    async with SessionLocal() as session:
        tasks = (await session.execute(select(TaskRow))).scalars().all()
        audits = (await session.execute(select(AuditRow))).scalars().all()
        pending = await cqrs.SqlAlchemyOutboxedEventRepository(session).get_many(
            topic="tasks",
        )
    assert len(tasks) == 1 and tasks[0].cancelled is True
    assert len(audits) == 1 and audits[0].task_id == 7
    assert len(pending) == 1
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
```

## What to notice

- **Same session.** `outbox_from_session(session)` receives the generator’s `AsyncSession`. The event handler asks for `AsyncSession` too. Under SEND, both resolves hit the same scoped instance.
- **Commit in the generator.** `yield` then `commit()`, `except` then `rollback()`. If the command handler called `outbox.commit()` (`session.commit()`), the domain-event writes would start a new transaction on the same session object.
- **SQLite outbox DDL.** `OutboxModel.id` uses `Identity()`, which SQLite does not autoincrement. The `CREATE TABLE` above matches [`examples/outbox/fastapi_outbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/outbox/fastapi_outbox.py). MySQL/Postgres can use `OutboxModel.metadata.create_all`.

Next: [which strategy to pick](strategies.md), or [di vs dishka vs dependency-injector](containers.md).
