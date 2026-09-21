# Why Scoped Dependencies

- **Back to Scoped Dependencies Overview**

  Start with the problem, a full example, and when to use SEND.

  [Back to Overview](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/index.md)

- **Tutorial**

  Command + domain event + outbox on one `AsyncSession`.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/tutorial/index.md)

______________________________________________________________________

The onboarding story now lives on [Overview](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/index.md) (three sentences, a copy-paste example, then when to pick SEND / HANDLER / NONE). This page keeps the before/after handler shape for old links.

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
