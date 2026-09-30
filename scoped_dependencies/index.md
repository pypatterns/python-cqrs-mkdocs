# Scoped Dependencies

By default, the container opens and closes a scope **inside** `resolve()`. A generator such as `async def session() -> AsyncIterator[AsyncSession]` therefore finishes **before** `handle`, which is why people inject factories.

Pass `scope_strategy=ScopeStrategy.SEND` and that session lives until `mediator.send()` returns — including domain-event handlers that run afterwards.

If you do not use generator providers, leave the default `ScopeStrategy.NONE` and change nothing.

## Example

Copy this as-is. Cleanup (`close`) runs after `handle`. Runnable file: [`examples/di/scoped_dependencies_di.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/di/scoped_dependencies_di.py).

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


class UoW:
    async def commit(self) -> None:
        print("commit")

    async def close(self) -> None:
        print("close")


async def uow_provider() -> typing.AsyncIterator[UoW]:
    uow = UoW()
    try:
        yield uow
    finally:
        await uow.close()  # after handle, not before


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
    await mediator.send(CancelTask(task_id=42))


if __name__ == "__main__":
    asyncio.run(main())
```

di scope=request is not a CQRS scope

`di`'s `scope="request"` only describes **provider lifetime** inside the `di` library. python-cqrs opens a CQRS scope **only** when you pass `scope_strategy=`. Without it, the generator still finishes before `handle`.

## Which strategy?

- **SEND** — one UoW per `send()` (command, fallback, and domain events).
- **HANDLER** — a fresh UoW per handler, including fallback (the primary rolls back first).
- **NONE** — legacy one-shot resolve; the default.

## Next

- **Tutorial**

  Command + domain event + outbox on one `AsyncSession` under SEND. The page to copy.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/tutorial/index.md)

- **Strategies**

  SEND vs HANDLER vs NONE, a decision table, and fallback in one screen.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/strategies/index.md)

- **Containers**

  Full `di`, dishka, and dependency-injector snippets (not fragments).

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/containers/index.md)

- **Advanced**

  `enter_scope`, `bind_scope`, several `send()` calls, FastAPI middleware.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/advanced/index.md)

- **Custom Container**

  When you need `SupportsScope.open_scope` for a DI library we do not ship.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/custom_container/index.md)

- **Troubleshooting**

  Generator finished too early, dirty sessions, streams, sagas.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/troubleshooting/index.md)

## Before / after

Without a CQRS scope you inject a factory and open the UoW yourself:

```python
class CancelTaskHandler(cqrs.RequestHandler[CancelTask, None]):
    def __init__(self, uow_factory: Callable[[], AbstractAsyncContextManager[IUoW]]) -> None:
        self._uow_factory = uow_factory

    async def handle(self, command: CancelTask) -> None:
        async with self._uow_factory() as uow:
            await uow.tasks.cancel(command.task_id)
            await uow.commit()
```

With `scope_strategy=ScopeStrategy.SEND`, inject the live object:

```python
class CancelTaskHandler(cqrs.RequestHandler[CancelTask, None]):
    def __init__(self, uow: IUoW) -> None:
        self._uow = uow

    async def handle(self, command: CancelTask) -> None:
        await self._uow.tasks.cancel(command.task_id)
        await self._uow.commit()
```

| Benefit             | Detail                                                        |
| ------------------- | ------------------------------------------------------------- |
| Less boilerplate    | No factory / context-manager parameters in handlers           |
| Shared unit of work | SEND: fallback and domain events reuse the command’s UoW      |
| Isolated fallback   | HANDLER: primary rolls back, then fallback gets a fresh scope |
| Guaranteed cleanup  | Exceptions still exit the scope (rollback / close)            |
| Easier tests        | Mock `IUoW` directly instead of a factory of context managers |
