# Saga Storage

- **Back to Saga Overview**

  Return to the Saga Pattern overview page with all topics.

  [Back to Overview](https://vadikko2.github.io/python-cqrs-mkdocs/saga/index.md)

Storage persists saga state and execution history, enabling recovery of interrupted sagas and ensuring eventual consistency.

## Overview

Two storage implementations:

| Storage Type              | Use Case             | Persistence                |
| ------------------------- | -------------------- | -------------------------- |
| **MemorySagaStorage**     | Testing, development | In-memory (not persistent) |
| **SqlAlchemySagaStorage** | Production           | Database (persistent)      |

## Storage Interface

```python
class ISagaStorage(abc.ABC):
    async def create_saga(saga_id, name, context) -> None
    async def update_context(saga_id, context, current_version: int | None = None) -> None
    async def update_status(saga_id, status) -> None
    async def log_step(saga_id, step_name, action, status, details=None) -> None
    async def load_saga_state(saga_id, *, read_for_update: bool = False) -> tuple[SagaStatus, dict, int]
    async def get_step_history(saga_id) -> list[SagaLogEntry]
    async def get_sagas_for_recovery(limit, max_recovery_attempts=5, stale_after_seconds=None, saga_name=None) -> list[uuid.UUID]
    async def increment_recovery_attempts(saga_id, new_status: SagaStatus | None = None) -> None
    async def set_recovery_attempts(saga_id, attempts: int) -> None

    # Optional: checkpoint commits (reduces storage load and deadlock risk)
    def create_run(self) -> contextlib.AbstractAsyncContextManager[SagaStorageRun]:
        """Yield a SagaStorageRun for one saga execution; raises NotImplementedError if not supported."""
        raise NotImplementedError("This storage does not support create_run()")
```

- **get_sagas_for_recovery** — Returns saga IDs that need recovery (RUNNING, COMPENSATING) with `recovery_attempts` < `max_recovery_attempts`, optionally filtered by staleness and by saga name. When `saga_name` is `None` (default), returns all saga types; when set, only sagas with that name. Used by recovery jobs.
- **increment_recovery_attempts** — Called automatically by `recover_saga()` on recovery failure; increments `recovery_attempts` and optionally updates status (e.g. to FAILED).
- **set_recovery_attempts** — Sets the recovery attempt counter to an explicit value. Use to reset after successfully recovering a step (e.g. set to `0`) or to set to the maximum so the saga is excluded from further recovery (e.g. mark as permanently failed without changing status).

### Checkpoint commits and `SagaStorageRun`

When a storage implements **`create_run()`**, the saga can run in a single session with **checkpoint commits**: one commit only at key points (after creating the saga and setting RUNNING, after each completed step, after each compensated step, at completion or failure) instead of committing after every storage call. This reduces the number of commits, shortens lock hold time, and lowers deadlock risk (e.g. with SQLAlchemy).

- **`SagaStorageRun`** — Protocol for a scoped “session” for a single saga. It exposes the same mutation/read methods as the storage (`create_saga`, `update_context`, `update_status`, `log_step`, `load_saga_state`, `get_step_history`) but **does not commit** automatically; the caller must call **`commit()`** at the desired checkpoints. **`rollback()`** aborts the run without persisting changes.
- **`create_run()`** — Returns an async context manager that yields a `SagaStorageRun`. If a storage does not support it (e.g. a custom implementation), it may raise `NotImplementedError`; in that case `SagaTransaction` falls back to the previous behaviour (no single session, no checkpoint commits; each call may commit immediately depending on the implementation).
- **`load_saga_state(..., read_for_update=True)`** — When loading state for recovery or exclusive update, the implementation can lock the row (e.g. `SELECT ... FOR UPDATE` in SQLAlchemy). Together with checkpoint commits, this shortens lock duration and reduces deadlock risk.

## Memory Storage

In-memory implementation for testing and development.

```python
import cqrs
from cqrs.saga import bootstrap
from cqrs.saga.storage.memory import MemorySagaStorage

storage = MemorySagaStorage()

# Register saga in SagaMap
def saga_mapper(mapper: cqrs.SagaMap) -> None:
    mapper.bind(OrderContext, OrderSaga)

# Create saga mediator using bootstrap
mediator = bootstrap.bootstrap(
    di_container=di_container,
    sagas_mapper=saga_mapper,
    saga_storage=storage,
)

# Access storage data
status, context_data, version = await storage.load_saga_state(saga_id)
history = await storage.get_step_history(saga_id)
```

**Features:**

- ✅ Fast and lightweight
- ✅ No database setup required
- ✅ Implements **`create_run()`** — yields `_MemorySagaStorageRun`; `commit()` and `rollback()` are no-ops, but the protocol is aligned with SQLAlchemy for tests.
- ❌ Not persistent (data lost on restart)

## SQLAlchemy Storage

Database-backed implementation for production. It uses a session factory. When the saga uses **`create_run()`**, all operations for one saga run go through a single **`AsyncSession`** and are committed only at checkpoints (after create + RUNNING, after each step, after each compensation step, at completion/failure), which reduces commits and deadlock risk.

### Database Schema

**saga_executions:**

- `id` (UUID) - Primary key
- `status` (VARCHAR) - PENDING, RUNNING, COMPENSATING, COMPLETED, FAILED
- `context` (JSON) - Serialized saga context; declared with `JSONType` (see [Database Support](#database-support))
- `version` (INTEGER) - Optimistic locking version (default: 1)
- `recovery_attempts` (INTEGER) - Number of failed recovery attempts (default: 0); used by `get_sagas_for_recovery`, `increment_recovery_attempts`, and `set_recovery_attempts`
- `created_at`, `updated_at` (TIMESTAMP)

**saga_logs:**

- `id` (BIGSERIAL) - Primary key
- `saga_id` (UUID) - Foreign key
- `step_name` (VARCHAR)
- `action` (VARCHAR) - "act" or "compensate"
- `status` (VARCHAR) - STARTED, COMPLETED, FAILED
- `details` (TEXT)
- `created_at` (TIMESTAMP)

**Indexes:** `saga_id`, `created_at`

### Database Support

The saga storage schema is verified against **MySQL** and **PostgreSQL** — both are covered by integration tests — and works on either without any configuration. See [Outbox Database Support](https://vadikko2.github.io/python-cqrs-mkdocs/outbox/databases/index.md) for the full database matrix and the Alembic setup shared by all SQLAlchemy models in the package.

The `context` column is declared with `cqrs.sqlalchemy_types.JSONType`, a dialect-aware type that resolves to a plain `sqlalchemy.JSON()` on **every** dialect, PostgreSQL and MySQL included. The rendered DDL is therefore identical to a bare `sqlalchemy.JSON` column:

```sql
-- PostgreSQL
context JSON NOT NULL

-- MySQL
context JSON NOT NULL COMMENT 'Serialized context'
```

No migration needed

`JSONType` ships without a single per-dialect registration, so upgrading the package does not change the `saga_executions` DDL on any database. Existing deployments need no migration.

#### Optional: `JSONB` on PostgreSQL

The point of the type is the extension point it adds. If you want PostgreSQL's binary JSON, register it once:

```python
from sqlalchemy.dialects import postgresql

from cqrs.sqlalchemy_types import DialectTypeHandler, JSONType

JSONType.register_dialect(
    "postgresql",
    DialectTypeHandler(type_factory=lambda dialect: postgresql.JSONB()),
)
```

The `context` column then renders as `context JSONB NOT NULL` on PostgreSQL and stays `JSON` everywhere else.

Why it can be worth it:

|          | `JSON`                             | `JSONB`                                      |
| -------- | ---------------------------------- | -------------------------------------------- |
| Storage  | Text, re-parsed on every access    | Decomposed binary form                       |
| Indexing | No GIN indexes                     | GIN indexes, containment operators like `@>` |
| Writes   | Cheaper                            | Slightly more expensive                      |
| Fidelity | Preserves key order and duplicates | Does not preserve key order                  |

So `JSONB` pays off if you intend to **query sagas by the content of `context`** — for example finding all sagas for a given order id. If `context` is only ever read back whole by the saga engine, plain `JSON` is fine and the default is the cheaper choice.

Existing PostgreSQL deployments need a manual migration

Registering the handler only changes what *new* DDL renders to. An existing `saga_executions` table keeps its `json` column until you convert it yourself:

```sql
ALTER TABLE saga_executions ALTER COLUMN context TYPE jsonb USING context::jsonb;
```

On a large table this rewrites every row while holding an `ACCESS EXCLUSIVE` lock, so schedule it like any other rewriting migration.

No `bind`/`result` converters for JSON

Serialization stays the responsibility of the dialect's JSON type, so the handler needs only `type_factory`. You still have to register **before the first use** — bind/result processors are memoized per dialect instance — and in both the application entry point and `alembic/env.py`; the reasoning is spelled out in [Register before the first use](https://vadikko2.github.io/python-cqrs-mkdocs/outbox/databases/#step-4-register-before-the-first-use-not-later).

### Usage

The storage requires an `async_sessionmaker` to create short-lived sessions for each operation.

```python
import uuid
import cqrs
from cqrs.saga import bootstrap
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from cqrs.saga.storage.sqlalchemy import SqlAlchemySagaStorage, Base

# Setup Engine with connection pool
engine = create_async_engine(
    "postgresql+asyncpg://user:pass@localhost/db",
    pool_size=20,
    max_overflow=10,
)

# Create session factory (factory, NOT session instance)
session_factory = async_sessionmaker(engine, expire_on_commit=False)

# Initialize tables (run once)
async with engine.begin() as conn:
    await conn.run_sync(Base.metadata.create_all)

# Initialize storage with session FACTORY
storage = SqlAlchemySagaStorage(session_factory)

# Register saga in SagaMap
def saga_mapper(mapper: cqrs.SagaMap) -> None:
    mapper.bind(OrderContext, OrderSaga)

# Create saga mediator using bootstrap
mediator = bootstrap.bootstrap(
    di_container=di_container,
    sagas_mapper=saga_mapper,
    saga_storage=storage,
)

# Execute saga
context = OrderContext(...)
saga_id = uuid.uuid4()

# With SqlAlchemySagaStorage, commits occur at checkpoints (after each step, etc.)
async for step_result in mediator.stream(context, saga_id=saga_id):
    print(f"Step: {step_result.step_type.__name__}")
```

### Transaction Management

**SqlAlchemySagaStorage** implements **`create_run()`**: it yields a **`_SqlAlchemySagaStorageRun`** backed by a single **`AsyncSession`** per saga run. All mutations go through that session and are committed only when the saga calls **`run.commit()`** at checkpoints (after creating the saga and setting RUNNING, after each completed step, after each compensated step, at completion or failure). On exception within the run context, the run's **`rollback()`** is invoked.

This design ensures:

- **Fewer commits** — One commit per checkpoint instead of per storage call.
- **Shorter lock time** — With `load_saga_state(..., read_for_update=True)`, the row is locked only for the duration of the run; checkpoint commits shorten that duration and reduce deadlock risk.
- **Crash safety** — Completed checkpoints are persisted; recovery can resume from the last checkpoint.
- **Backward compatibility** — Custom storages that do not implement `create_run()` continue to work; the saga falls back to calling storage methods directly (no single session).

### Concurrency Control

The storage implementation provides two mechanisms to handle concurrency in distributed environments:

#### 1. Optimistic Locking (Versioning)

To prevent "lost updates" when multiple steps might update the context simultaneously (though sagas typically execute sequentially), the `version` column is used.

- `update_context` accepts an optional `current_version`.
- If provided, the storage checks if `version == current_version`.
- If matched, it updates the context and increments the version (`version + 1`).
- If not matched, it raises `SagaConcurrencyError`, indicating the state was modified by another process.

#### 2. Row Locking (Recovery Safety and Deadlock Mitigation)

When recovering or exclusively updating a saga (e.g., after a crash), it is critical that only one worker picks up the saga to avoid duplicate execution.

- `load_saga_state(..., read_for_update=True)` uses `SELECT ... FOR UPDATE` (in SQL databases), acquiring a row-level lock on the saga execution record.
- Other workers attempting to lock the same saga will wait or fail, ensuring exclusive access.
- When the storage supports **`create_run()`**, the saga holds the session (and thus the lock) only between checkpoints; commits are done at key points, which shortens lock duration and reduces deadlock risk.

## Choosing Storage

**Memory Storage:**

- ✅ Unit tests, development
- ❌ Not persistent

**SQLAlchemy Storage:**

- ✅ Production, multi-process
- ✅ Recovery after restarts
- ✅ Audit trail
- ✅ Robust transaction management

## Best Practices

1. **Use persistent storage in production** — Memory storage loses data on restart
1. **Configure Connection Pool** — Set appropriate `pool_size` and `max_overflow` for your load.
1. **Create indexes** — Index `saga_id` and `created_at` for better performance
1. **Monitor storage size** — Archive old saga logs periodically
