---
title: Scoped Containers
description: Full di, dishka, and dependency-injector snippets for python-cqrs scoped dependencies.
---

# Containers

<div class="grid cards" markdown>

-   :material-home: **Back to Scoped Dependencies Overview**

    Return to the Scoped Dependencies overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

---

| Feature | `di` | dishka | dependency-injector |
|---------|------|--------|---------------------|
| Adapter | raw `di.Container` or `DIContainer` | `DishkaCQRSContainer` | `DependencyInjectorCQRSContainer` |
| Per-request CQRS scope | ✅ | ✅ (`Scope.REQUEST`) | ❌ (no-op `SupportsScope`) |
| Async generator providers | ✅ | ✅ | ❌ |
| Extra install | default | `pip install python-cqrs[dishka]` | default |

!!! note "di scope=request ≠ CQRS scope"
    Binding with `scope="request"` (or dishka `Scope.REQUEST`) only configures the **DI library**. The generator stays open across `handle` only when bootstrap gets `scope_strategy=ScopeStrategy.SEND` (or `HANDLER`).

## `di`

```python
from __future__ import annotations

import asyncio
import typing

import di
from di import dependent

import cqrs
from cqrs.requests import bootstrap


class IUoW(typing.Protocol):
    async def commit(self) -> None: ...
    async def close(self) -> None: ...


class UoW:
    async def commit(self) -> None:
        pass

    async def close(self) -> None:
        pass


async def uow_provider() -> typing.AsyncIterator[UoW]:
    uow = UoW()
    try:
        yield uow
    finally:
        await uow.close()


class CancelTask(cqrs.Request):
    task_id: int


class CancelTaskHandler(cqrs.RequestHandler[CancelTask, None]):
    def __init__(self, uow: IUoW) -> None:
        self._uow = uow

    @property
    def events(self) -> typing.List[cqrs.Event]:
        return []

    async def handle(self, request: CancelTask) -> None:
        await self._uow.commit()


def setup_di() -> di.Container:
    container = di.Container()
    container.bind(
        di.bind_by_type(
            dependent.Dependent(uow_provider, scope="request"),
            IUoW,
        ),
    )
    return container


def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(CancelTask, CancelTaskHandler)


async def main() -> None:
    mediator = bootstrap.bootstrap(
        di_container=setup_di(),
        commands_mapper=commands_mapper,
        scope_strategy=cqrs.ScopeStrategy.SEND,
    )
    await mediator.send(CancelTask(task_id=1))


if __name__ == "__main__":
    asyncio.run(main())
```

See [`examples/di/scoped_dependencies_di.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/di/scoped_dependencies_di.py). SQLAlchemy + outbox: [Tutorial](tutorial.md).

## dishka

Register **handlers** as dishka providers (`Scope.REQUEST`). Install with `pip install python-cqrs[dishka]`.

```python
from __future__ import annotations

import asyncio
import typing

from dishka import Provider, Scope, make_async_container, provide

import cqrs
from cqrs.container.dishka import DishkaCQRSContainer
from cqrs.requests import bootstrap


class UoW:
    def __init__(self) -> None:
        self.id = id(self)

    async def commit(self) -> None:
        pass


class CancelTask(cqrs.Request):
    task_id: int


class CancelTaskHandler(cqrs.RequestHandler[CancelTask, None]):
    def __init__(self, uow: UoW) -> None:
        self._uow = uow

    @property
    def events(self) -> typing.List[cqrs.Event]:
        return []

    async def handle(self, request: CancelTask) -> None:
        await self._uow.commit()


class AppProvider(Provider):
    @provide(scope=Scope.REQUEST)
    async def uow(self) -> typing.AsyncIterator[UoW]:
        uow = UoW()
        try:
            yield uow
        finally:
            pass

    cancel_handler = provide(CancelTaskHandler, scope=Scope.REQUEST)


def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(CancelTask, CancelTaskHandler)


async def main() -> None:
    dishka = make_async_container(AppProvider())
    mediator = bootstrap.bootstrap(
        di_container=DishkaCQRSContainer(dishka),
        commands_mapper=commands_mapper,
        scope_strategy=cqrs.ScopeStrategy.SEND,
    )
    await mediator.send(CancelTask(task_id=7))
    await dishka.close()


if __name__ == "__main__":
    asyncio.run(main())
```

See [`examples/di/scoped_dependencies_dishka.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/di/scoped_dependencies_dishka.py).

## dependency-injector

The library has no per-request scope API, so the adapter does **not** implement `SupportsScope`. Generator providers will not stay alive until `handle` finishes.

Use `providers.Singleton` / `Resource` for process-level resources (pools) and `providers.Factory` for a new UoW per resolve **without** generator finalization. For a scoped session / outbox, prefer `di` or dishka.

```python
from __future__ import annotations

import asyncio
import typing

from dependency_injector import containers, providers

import cqrs
from cqrs.container.dependency_injector import DependencyInjectorCQRSContainer
from cqrs.requests import bootstrap


class ConnectionPool:
    pass


class UoW:
    def __init__(self, pool: ConnectionPool) -> None:
        self.pool = pool

    async def commit(self) -> None:
        pass


class CancelTask(cqrs.Request):
    task_id: int


class CancelTaskHandler(cqrs.RequestHandler[CancelTask, None]):
    def __init__(self, uow: UoW) -> None:
        self._uow = uow

    @property
    def events(self) -> typing.List[cqrs.Event]:
        return []

    async def handle(self, request: CancelTask) -> None:
        await self._uow.commit()


class ApplicationContainer(containers.DeclarativeContainer):
    pool = providers.Singleton(ConnectionPool)
    uow = providers.Factory(UoW, pool=pool)
    cancel_task_handler = providers.Factory(CancelTaskHandler, uow=uow)


def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(CancelTask, CancelTaskHandler)


async def main() -> None:
    app = ApplicationContainer()
    cqrs_container = DependencyInjectorCQRSContainer()
    cqrs_container.attach_external_container(app)
    mediator = bootstrap.bootstrap(
        di_container=cqrs_container,
        commands_mapper=commands_mapper,
        scope_strategy=cqrs.ScopeStrategy.SEND,  # no-op for this adapter
    )
    await mediator.send(CancelTask(task_id=1))


if __name__ == "__main__":
    asyncio.run(main())
```

See [`examples/di/scoped_dependencies_dependency_injector.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/di/scoped_dependencies_dependency_injector.py).
