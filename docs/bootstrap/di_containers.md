# Di Containers

<div class="grid cards" markdown>

-   :material-home: **Back to Bootstrap Overview**

    Return to the Bootstrap overview page with all configuration options.

    [:octicons-arrow-left-24: Back to Overview](index.md)

-   :material-puzzle: **Dependency Injection**

    Container setup, scopes, and resolving handlers and dependencies.

    [:octicons-arrow-right-24: Read More](../di.md)

</div>

---

## Overview

dishka is [Testing dishka](../testing/dishka.md). dependency-injector is [Testing dependency-injector](../testing/dependency_injector.md).

The bootstrap functions support multiple DI container implementations.

| Container | Library | Default | Best For |
|-----------|---------|---------|----------|
| **SimpleContainer** | none (base install) | ✅ Yes | Handlers with no constructor dependencies, or a few registered instances |
| **di.Container** | `di` (`python-cqrs[di]`) | ❌ No | Type-based injection and `ScopeStrategy.SEND` |
| **DishkaCQRSContainer** | dishka (`python-cqrs[dishka]`) | ❌ No | Apps already using dishka / request scopes |
| **CQRSContainer** | `dependency-injector` (`python-cqrs[dependency-injector]`) | ❌ No | Large, complex applications |

!!! tip "Container Choice"
    Omit `di_container` for `SimpleContainer`. Use `di` when handlers need injection or a shared unit of work. Use dishka when you already rely on it for request scopes. Use `dependency-injector` only if you need advanced features like configuration management or nested containers — it does not implement CQRS `SupportsScope` (see [Scoped Dependencies](../scoped_dependencies/containers.md)).

!!! tip "Scoped UoW"
    Pass `scope_strategy=ScopeStrategy.SEND` to bootstrap so generator providers finalize after `handle`; the default `ScopeStrategy.NONE` opens no scopes. SEND infers sequential events (`concurrent_event_handle_enable=None` → `False`) and shares the same UoW with fallback. A plain container is enough — mediators wrap it internally. Details: [Scoped Dependencies](../scoped_dependencies/index.md).

### di.Container

The `di` library is an optional container (`python-cqrs[di]`):

```python
import abc
import di
from di import dependent

class ServiceProtocol(abc.ABC):
    @abc.abstractmethod
    async def do_work(self) -> None:
        pass

class ServiceImpl(ServiceProtocol):
    async def do_work(self) -> None:
        print("Working...")

# Setup DI container
container = di.Container()
container.bind(
    di.bind_by_type(
        dependent.Dependent(ServiceImpl, scope="request"),
        ServiceProtocol,
    )
)

mediator = bootstrap.bootstrap(
    di_container=container,
    commands_mapper=commands_mapper,
)
```

### CQRSContainer (dependency-injector)

The `DependencyInjectorCQRSContainer` adapter allows using the `dependency-injector` library:

```python
from dependency_injector import containers, providers
from cqrs.container.dependency_injector import DependencyInjectorCQRSContainer

class ApplicationContainer(containers.DeclarativeContainer):
    # Define your services
    service = providers.Factory(ServiceImpl)

# Create CQRS container adapter and attach the DI container
cqrs_container = DependencyInjectorCQRSContainer()
cqrs_container.attach_external_container(ApplicationContainer())

mediator = bootstrap.bootstrap(
    di_container=cqrs_container,
    commands_mapper=commands_mapper,
)
```

### DishkaCQRSContainer

Install with `pip install python-cqrs[dishka]`. Register handlers as dishka providers:

```python
from dishka import Provider, Scope, make_async_container, provide
from cqrs.container.dishka import DishkaCQRSContainer

class AppProvider(Provider):
    @provide(scope=Scope.REQUEST)
    def service(self) -> ServiceImpl:
        return ServiceImpl()

    handler = provide(MyHandler, scope=Scope.REQUEST)

mediator = bootstrap.bootstrap(
    di_container=DishkaCQRSContainer(make_async_container(AppProvider())),
    commands_mapper=commands_mapper,
)
```

See [Scoped Dependencies — Containers](../scoped_dependencies/containers.md) for full details.
