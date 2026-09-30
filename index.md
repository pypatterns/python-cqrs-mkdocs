# Python CQRS

Event-Driven Architecture Framework for Distributed Systems

[🐙 Star if cool ⭐ ✨ ✨](https://github.com/vadikko2/python-cqrs)

[📦 PyPI](https://pypi.org/project/python-cqrs/) [📊 Downloads](https://clickpy.clickhouse.com/dashboard/python-cqrs)

Breaking Changes in v5.0.0

Starting with version 5.0.0, **Pydantic support will become optional**. The default implementations of `Request`, `Response`, `DomainEvent`, and `NotificationEvent` will be migrated to dataclasses-based implementations.

See the [planned release discussion on GitHub](https://github.com/vadikko2/python-cqrs/discussions/57) for the full list of breaking changes and migration details.

______________________________________________________________________

## Core Features

- **Bootstrap**

  Quick project setup and configuration with automatic DI container setup.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/index.md)

- **Request Handlers**

  Handle commands and queries with full type safety and async support.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/request_handler/index.md)

- **Saga Pattern**

  Orchestrated Saga for distributed transactions with automatic compensation.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/saga/index.md)

- **Event Handling**

  Process domain events with parallel processing and runtime execution.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/event_handler/index.md)

- **Transaction Outbox**

  Guaranteed event delivery with at-least-once semantics.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/outbox/index.md)

- **Chain of Responsibility**

  Sequential request processing with flexible handler chaining.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/chain_of_responsibility/index.md)

- **Streaming**

  Incremental processing with real-time progress updates via SSE.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/stream_handling/index.md)

- **Integrations**

  FastAPI and FastStream integrations out of the box.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/fastapi/index.md)

- **Mermaid Diagrams**

  Visualize architecture patterns and flows with interactive Mermaid diagrams.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/mermaid/index.md)

______________________________________________________________________

## What is it?

**Python CQRS** is a framework for implementing the CQRS (Command Query Responsibility Segregation) pattern in Python applications. It helps separate read and write operations, improving scalability, performance, and code maintainability.

**Key Highlights:**

- **Performance** — Separation of commands and queries, parallel event processing
- **Reliability** — Transaction Outbox for guaranteed event delivery, Saga with compensation support and eventual consistency
- **Flexible Types** — Easy integration with any type: [Pydantic, dataclasses, msgspec, attrs, TypedDict and more](https://vadikko2.github.io/python-cqrs-mkdocs/request_response_types/index.md)
- **Ready Integrations** — FastAPI and FastStream out of the box
- **Simple Setup** — Bootstrap for quick configuration
- **Proven Patterns** — CQRS, Saga, Outbox and more to keep services decoupled and maintainable

______________________________________________________________________

## Project status

| Group                     | Badges |
| ------------------------- | ------ |
| Python version & PyPI     |        |
| Downloads                 |        |
| Quality & CI              |        |
| Documentation & community |        |

______________________________________________________________________

## Installation

Install Python CQRS using pip or uv:

**Using pip:**

```bash
pip install python-cqrs
```

**Using uv:**

```bash
uv pip install python-cqrs
```

Requirements

Python 3.10+ (tested on 3.10–3.13)

______________________________________________________________________

## Quick Start

```python
import di
import cqrs
from cqrs.requests import bootstrap

# Define command, response and handler
class CreateUserCommand(cqrs.Request):
    email: str
    name: str

class CreateUserResponse(cqrs.Response):
    user_id: str

class CreateUserHandler(cqrs.RequestHandler[CreateUserCommand, CreateUserResponse]):
    async def handle(self, request: CreateUserCommand) -> CreateUserResponse:
        # Your business logic here
        user_id = f"user_{request.email}"
        return CreateUserResponse(user_id=user_id)

# Bootstrap and use
mediator = bootstrap.bootstrap(
    di_container=di.Container(),
    commands_mapper=lambda m: m.bind(CreateUserCommand, CreateUserHandler),
)

result = await mediator.send(CreateUserCommand(email="user@example.com", name="John"))
```

See [Bootstrap](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/index.md) for detailed setup instructions.
