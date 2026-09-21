---
title: Dependency Injection in python-cqrs
description: Configure DI containers (di and dependency-injector) for handlers and mediators in python-cqrs.
---

# Dependency Injection

Dependency Injection (DI) is a design pattern that allows injecting dependencies into application components, simplifying their management and improving code testability.

## Overview

The `python-cqrs` package supports multiple DI container libraries:

- **`di`** — Lightweight, modern dependency injection library (default)
- **`dependency-injector`** — Feature-rich DI library with configuration management and FastAPI integration
- **dishka** — Optional (`pip install python-cqrs[dishka]`) with first-class request scopes

Both `di` and dishka allow generator providers whose cleanup runs when the CQRS scope exits. See [Scoped Dependencies](scoped_dependencies/index.md).

!!! note "Prerequisites"
    This section assumes you've already configured [Bootstrap](bootstrap/index.md). The DI container is passed to bootstrap functions to resolve handlers and their dependencies.

!!! tip "Next Steps"
    After understanding DI, proceed to [Request Handlers](request_handler/index.md) to learn how handlers use dependency injection. For request-scoped UoW / sessions, read [Scoped Dependencies](scoped_dependencies/index.md).

## Supported Libraries

| Feature | `di` | dishka | `dependency-injector` |
|---------|------|--------|----------------------|
| **Default** | ✅ Yes (default) | ❌ Optional extra | ❌ No |
| **Type-based resolution** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Per-request scope (CQRS)** | ✅ Yes | ✅ Yes | ❌ No (`SupportsScope` not implemented) |
| **Async generator providers** | ✅ Yes | ✅ Yes | ❌ No |
| **Configuration management** | ❌ No | ❌ No | ✅ Yes (YAML, dict, Pydantic) |
| **Resource management** | ❌ No | ✅ Yes | ✅ Yes |
| **FastAPI integration** | ✅ Yes | ✅ Yes | ✅ Yes (direct wiring) |
| **Nested containers** | ❌ No | ✅ Yes | ✅ Yes |
| **Learning curve** | 🟢 Easy | 🟢 Easy | 🟡 Moderate |
| **Best for** | Small to medium apps | Apps already on dishka | Large, complex apps |

### `di` Library

The `di` library is the default DI container for `python-cqrs`. It provides:

| Feature | Description |
|---------|-------------|
| **Type-based resolution** | Automatic dependency resolution by type |
| **Scoped dependencies** | Support for singleton, request, and scoped lifetimes |
| **Simple API** | Easy to use and configure |
| **Type safety** | Full type checking support |

!!! tip "When to use `di`"
    Use `di` for most applications. It's lightweight, simple, and provides everything you need for dependency injection.

### `dependency-injector` Library

The `dependency-injector` library offers advanced features:

| Feature | Description |
|---------|-------------|
| **Configuration management** | Built-in support for YAML, dict, and Pydantic settings |
| **Resource management** | Automatic initialization and cleanup of resources |
| **Container wiring** | Direct injection into FastAPI endpoints |
| **Nested containers** | Better organization for large applications |

!!! info "When to use `dependency-injector`"
    Use `dependency-injector` when you need advanced features like configuration management, resource lifecycle, or nested containers for large applications.


## Key Concepts

### Binding Implementations

Dependencies are bound by type, allowing the container to automatically resolve implementations:

```python
container.bind(
    di.bind_by_type(
        Dependent(ImplementationClass, scope="request"),
        InterfaceProtocol
    )
)
```

### Dependency Scopes

The `di` library supports different scopes:

| Scope | Lifetime | Use Case |
|-------|----------|----------|
| **`"singleton"`** | One instance per container (shared across all requests) | Stateless services, configuration |
| **`"request"`** | Provider lifetime inside `di` / dishka. Becomes one instance per CQRS `send()` / handler **only** if you also pass `scope_strategy=` | Stateful services, database sessions / UoW |
| **`"scoped"`** | One instance per scope (custom scope management) | Request-scoped resources |

!!! tip "CQRS request scope"
    `di`'s `scope="request"` is **not** a CQRS scope by itself. Without `scope_strategy=`, a generator provider still finishes before `handle`. Pass `scope_strategy=ScopeStrategy.SEND` so `"request"` dependencies live for the whole `mediator.send()` (including domain events). Details: [Scoped Dependencies](scoped_dependencies/index.md).

<details>
<summary><strong>Scope Examples</strong></summary>

```python
# Singleton - shared across all requests
container.bind(
    di.bind_by_type(
        Dependent(ConfigService, scope="singleton"),
        ConfigServiceProtocol
    )
)

# Request - new instance per request
container.bind(
    di.bind_by_type(
        Dependent(DatabaseConnection, scope="request"),
        DatabaseProtocol
    )
)
```

</details>

### Automatic Resolution

Handlers receive dependencies automatically through constructor injection:

```python
class MyHandler(RequestHandler[MyCommand, None]):
    def __init__(self, service: ServiceProtocol) -> None:
        self._service = service
```

The container automatically resolves `ServiceProtocol` and injects it into the handler.

## Integration with Bootstrap

DI containers are integrated with the bootstrap process:

```python
mediator = bootstrap.bootstrap(
    di_container=container,
    commands_mapper=commands_mapper,
    queries_mapper=queries_mapper,
    domain_events_mapper=domain_events_mapper,
)
```

The container is used to resolve all handlers and their dependencies automatically.

## Benefits

Using dependency injection with `python-cqrs` provides:

| Benefit | Description |
|---------|-------------|
| **Simplified management** | Container handles creation and lifecycle |
| **Improved testability** | Easy to mock dependencies for unit testing |
| **Flexibility** | Swap implementations without changing core code |
| **Separation of concerns** | Dependencies explicitly declared |
| **Configuration management** | Centralized dependency configuration |

## Best Practices

| Practice | Description | Example |
|----------|-------------|---------|
| **Use interfaces** | Always bind implementations to interfaces, not concrete classes | `ServiceProtocol` → `ServiceImplementation` |
| **Choose scopes wisely** | Use singleton for stateless services, request for stateful ones | Config: singleton, DB: request |
| **Keep constructors simple** | Avoid complex logic in constructors | Move logic to methods |
| **UoW / sessions: generator + SEND** | Do not inject a UoW factory as best practice. Bind an async generator and pass `scope_strategy=ScopeStrategy.SEND` so cleanup runs after `handle` | See [Scoped Dependencies](scoped_dependencies/index.md) |
| **Factories for construction only** | Use a factory when the object does not need a request-scoped lifetime | `create_database_connection()` for a pool, not for the per-send session |
| **Test with mocks** | Always test handlers with mocked dependencies | Mock `ServiceProtocol` in tests |

!!! warning "Common Mistakes"
    - ❌ Binding concrete classes instead of interfaces
    - ❌ Using singleton for stateful services
    - ❌ Injecting a UoW/session **factory** instead of a generator + `scope_strategy=SEND`
    - ❌ Complex logic in constructors
    - ❌ Not testing with mocks

!!! tip "Testing Tips"
    Always test handlers with mocked dependencies. This ensures your handlers are testable and don't depend on external services.
