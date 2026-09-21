---
title: Why Scoped Dependencies
description: Generator providers need a CQRS-owned scope so UoW cleanup runs after handle.
---

# Why Scoped Dependencies

<div class="grid cards" markdown>

-   :material-home: **Back to Scoped Dependencies Overview**

    Start with the problem, a full example, and when to use SEND.

    [:octicons-arrow-left-24: Back to Overview](index.md)

-   :material-school: **Tutorial**

    Command + domain event + outbox on one `AsyncSession`.

    [:octicons-arrow-right-24: Read More](tutorial.md)

</div>

---

The onboarding story now lives on [Overview](index.md) (three sentences, a copy-paste example, then when to pick SEND / HANDLER / NONE). This page keeps the before/after handler shape for old links.

```python
# Before — factory boilerplate
class CancelTaskHandler(cqrs.RequestHandler[CancelTask, None]):
    def __init__(self, uow_factory: Callable[[], AbstractAsyncContextManager[IUoW]]) -> None:
        self._uow_factory = uow_factory

    async def handle(self, command: CancelTask) -> None:
        async with self._uow_factory() as uow:
            await uow.tasks.cancel(command.task_id)
            await uow.commit()
```

```python
# After — live dependency; cleanup on CQRS scope exit
class CancelTaskHandler(cqrs.RequestHandler[CancelTask, None]):
    def __init__(self, uow: IUoW) -> None:
        self._uow = uow

    async def handle(self, command: CancelTask) -> None:
        await self._uow.tasks.cancel(command.task_id)
        await self._uow.commit()
```

Enable that with `scope_strategy=ScopeStrategy.SEND` on bootstrap. `di`'s `scope="request"` alone does not open a CQRS scope.
