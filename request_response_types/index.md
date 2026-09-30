# Request and Response Types

## Overview

The `python-cqrs` library provides flexible support for different types of request and response implementations. All request types must implement the `IRequest` interface, and all response types must implement the `IResponse` interface. This allows you to choose the best implementation for your specific use case.

Interface Requirements

Both `IRequest` and `IResponse` interfaces require:

- `to_dict()` method: Convert instance to dictionary
- `from_dict()` classmethod: Create instance from dictionary

## Navigation

- **Pydantic**

  Default implementation with validation and serialization features.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/request_response_types/pydantic/index.md)

- **Dataclasses**

  Lightweight implementation using Python's standard library.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/request_response_types/dataclasses/index.md)

- **Standard Classes**

  Full control with custom Python classes.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/request_response_types/standard_classes/index.md)

- **NamedTuple**

  Immutable data structures with memory efficiency.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/request_response_types/namedtuple/index.md)

- **Attrs**

  Advanced features beyond standard dataclasses.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/request_response_types/attrs/index.md)

- **Msgspec**

  High-performance serialization for microservices.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/request_response_types/msgspec/index.md)

- **TypedDict**

  Type hints with zero runtime overhead.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/request_response_types/typeddict/index.md)

- **Mixed Usage**

  Combining different types for requests and responses.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/request_response_types/mixed_usage/index.md)

- **Best Practices**

  Recommendations for choosing and using types.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/request_response_types/best_practices/index.md)

## Comparison Table

| Type                         | Validation           | Performance | Dependencies  | Best For                       |
| ---------------------------- | -------------------- | ----------- | ------------- | ------------------------------ |
| **PydanticRequest/Response** | ✅ Runtime           | Medium      | pydantic      | Web APIs, validation needed    |
| **DCRequest/DCResponse**     | ❌                   | Fast        | None (stdlib) | Internal systems, lightweight  |
| **Standard Classes**         | Custom               | Fast        | None          | Full control, custom logic     |
| **NamedTuple**               | ❌                   | Very Fast   | None (stdlib) | Immutable, memory-efficient    |
| **Attrs**                    | ✅ (with validators) | Fast        | attrs         | More features than dataclasses |
| **Msgspec**                  | ✅ Runtime           | Very Fast   | msgspec       | High-performance microservices |
| **TypedDict**                | ❌ (static only)     | Fastest     | None (stdlib) | Type hints, zero overhead      |

## Quick Decision Guide

### Need Validation?

- **Pydantic** — Best for web APIs with comprehensive validation
- **Msgspec** — High-performance alternative with validation
- **Attrs** — Custom validators with more flexibility

### Need Performance?

- **Msgspec** — Fastest serialization (Rust-based)
- **Dataclasses** — Fast, no dependencies
- **NamedTuple** — Very fast, immutable

### Need Lightweight?

- **Dataclasses** — Standard library, no dependencies
- **NamedTuple** — Minimal overhead
- **TypedDict** — Zero runtime overhead

### Need Flexibility?

- **Standard Classes** — Full control over implementation
- **Attrs** — Advanced features and customization
- **Pydantic** — Rich ecosystem and integrations

## Interface Contract

All request and response types must implement the following interface:

```python
from abc import ABC, abstractmethod
from typing import Self

class IRequest(ABC):
    @abstractmethod
    def to_dict(self) -> dict:
        """Convert instance to dictionary."""
        raise NotImplementedError

    @classmethod
    @abstractmethod
    def from_dict(cls, **kwargs) -> Self:
        """Create instance from dictionary."""
        raise NotImplementedError

class IResponse(ABC):
    @abstractmethod
    def to_dict(self) -> dict:
        """Convert instance to dictionary."""
        raise NotImplementedError

    @classmethod
    @abstractmethod
    def from_dict(cls, **kwargs) -> Self:
        """Create instance from dictionary."""
        raise NotImplementedError
```

## Built-in Types

The library provides two built-in implementations that you can use directly:

1. **PydanticRequest/PydanticResponse** (aliased as `Request`/`Response`)
1. Default implementation
1. Runtime validation
1. Type coercion
1. JSON Schema support
1. **DCRequest/DCResponse**
1. Lightweight dataclass-based
1. No external dependencies
1. Fast and simple

Prerequisites

Understanding of [Request Handlers](https://vadikko2.github.io/python-cqrs-mkdocs/request_handler/index.md) is recommended. Request and response types are used in handler definitions.

Related Topics

- [Request Handlers](https://vadikko2.github.io/python-cqrs-mkdocs/request_handler/index.md) — Learn how to use types in handlers
- [Bootstrap](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/index.md) — Setup and configuration
- [Dependency Injection](https://vadikko2.github.io/python-cqrs-mkdocs/di/index.md) — DI container usage
