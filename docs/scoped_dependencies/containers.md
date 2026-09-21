---
title: Scoped Containers
description: Use di, dishka, and dependency-injector with python-cqrs scopes.
---

# Containers

| Feature | `di` | dishka | dependency-injector |
|---------|------|--------|---------------------|
| Adapter | `DIContainer` / raw `di.Container` | `DishkaCQRSContainer` | `DependencyInjectorCQRSContainer` |
| Per-request scope | ✅ | ✅ (`Scope.REQUEST`) | ❌ (no-op `SupportsScope`) |
| Async generator providers | ✅ (via `async with enter_scope`) | ✅ | ❌ |
| Nested / joined scopes | ✅ (`reuse_existing`) | ✅ | — |
| Context injection | — | ✅ (`open_scope(context=...)`) | — |
| Extra install | default | `pip install python-cqrs[dishka]` | default |

## `di`

```python
async def uow_provider() -> typing.AsyncIterator[IUoW]:
    async with create_uow() as uow:
        yield uow

container = di.Container()
container.bind(di.bind_by_type(dependent.Dependent(uow_provider, scope="request"), IUoW))
mediator = bootstrap.bootstrap(
    di_container=container,
    commands_mapper=...,
    scope_strategy=ScopeStrategy.SEND,
)
```

See `examples/di/scoped_dependencies_di.py`.

## dishka

```python
from dishka import Provider, Scope, make_async_container, provide
from cqrs.container.dishka import DishkaCQRSContainer

class AppProvider(Provider):
    @provide(scope=Scope.REQUEST)
    async def uow(self) -> typing.AsyncIterator[IUoW]:
        async with create_uow() as uow:
            yield uow

    handler = provide(CancelTaskHandler, scope=Scope.REQUEST)

mediator = bootstrap.bootstrap(
    di_container=DishkaCQRSContainer(make_async_container(AppProvider())),
    commands_mapper=...,
    scope_strategy=ScopeStrategy.SEND,
)
```

Register handlers as dishka providers. See `examples/di/scoped_dependencies_dishka.py`.

## dependency-injector

The library has no per-request scope API, so the adapter does **not** implement `SupportsScope`. Use:

- `providers.Singleton` / `Resource` for process-level resources (pools)
- `providers.Factory` for a new UoW per resolve (without generator finalization)

For true scoped generators, prefer `di` or dishka. See `examples/di/scoped_dependencies_dependency_injector.py`.
