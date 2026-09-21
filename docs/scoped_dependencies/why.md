---
title: Why Scoped Dependencies
description: Remove factory boilerplate and guarantee UoW cleanup after handle.
---

# Why Scoped Dependencies

Without a framework-owned scope, containers open and close a scope **inside** `resolve()`. Generator providers finish before the handler runs, so you end up injecting factories:

```python
# Before — factory boilerplate (issue #70)
class CancelTaskHandler(cqrs.RequestHandler[CancelTask, None]):
    def __init__(self, uow_factory: Callable[[], AbstractAsyncContextManager[IUoW]]) -> None:
        self._uow_factory = uow_factory

    async def handle(self, command: CancelTask) -> None:
        async with self._uow_factory() as uow:
            await uow.tasks.cancel(command.task_id)
            await uow.commit()
```

With scopes enabled (`scope_strategy=ScopeStrategy.SEND` on bootstrap), inject the live dependency:

```python
# After
class CancelTaskHandler(cqrs.RequestHandler[CancelTask, None]):
    def __init__(self, uow: IUoW) -> None:
        self._uow = uow

    async def handle(self, command: CancelTask) -> None:
        await self._uow.tasks.cancel(command.task_id)
        await self._uow.commit()
```

## Benefits

| Benefit | Detail |
|---------|--------|
| Less boilerplate | No factory / context-manager parameters in handlers |
| Shared unit of work | With `ScopeStrategy.SEND`, fallback and domain events reuse the command’s UoW |
| Isolated fallback | With `ScopeStrategy.HANDLER`, each resolve+handle — **including fallback** — gets a fresh scope after the primary rolls back |
| Guaranteed cleanup | Exceptions still exit the scope (rollback / close) |
| Easier tests | Mock `IUoW` directly instead of a factory of context managers |
