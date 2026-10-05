# Python CQRS

Event-Driven Architecture Framework for Distributed Systems

[🐙 Star if cool ⭐ ✨ ✨](https://github.com/vadikko2/python-cqrs)

[📦 PyPI](https://pypi.org/project/python-cqrs/) [📊 Downloads](https://clickpy.clickhouse.com/dashboard/python-cqrs)

Documentation for python-cqrs 5.x

You are viewing **5.0** docs (dataclass defaults, optional Pydantic/SQLAlchemy, new package layout, `SagaMediator.execute`).

Migrating from 4.x? Follow the [4→5 migration guide](https://mkdocs.python-cqrs.dev/latest/migration/4-to-5/index.md). Use the version selector for frozen **4.0** docs.

______________________________________________________________________

## Core Features

- **Bootstrap**

  Quick project setup and configuration with automatic DI container setup.

  [Read More](https://mkdocs.python-cqrs.dev/latest/bootstrap/index.md)

- **Request Handlers**

  Handle commands and queries with full type safety and async support.

  [Read More](https://mkdocs.python-cqrs.dev/latest/request_handler/index.md)

- **Saga Pattern**

  Orchestrated Saga for distributed transactions with automatic compensation.

  [Read More](https://mkdocs.python-cqrs.dev/latest/saga/index.md)

- **Event Handling**

  Process domain events with parallel processing and runtime execution.

  [Read More](https://mkdocs.python-cqrs.dev/latest/event_handler/index.md)

- **Transaction Outbox**

  Guaranteed event delivery with at-least-once semantics.

  [Read More](https://mkdocs.python-cqrs.dev/latest/outbox/index.md)

- **Chain of Responsibility**

  Sequential request processing with flexible handler chaining.

  [Read More](https://mkdocs.python-cqrs.dev/latest/chain_of_responsibility/index.md)

- **Streaming**

  Incremental processing with real-time progress updates via SSE.

  [Read More](https://mkdocs.python-cqrs.dev/latest/stream_handling/index.md)

- **Integrations**

  FastAPI and FastStream integrations out of the box.

  [Read More](https://mkdocs.python-cqrs.dev/latest/fastapi/index.md)

- **Mermaid Diagrams**

  Visualize architecture patterns and flows with interactive Mermaid diagrams.

  [Read More](https://mkdocs.python-cqrs.dev/latest/mermaid/index.md)

______________________________________________________________________

## What is it?

**Python CQRS** is a framework for implementing the CQRS (Command Query Responsibility Segregation) pattern in Python applications. It helps separate read and write operations, improving scalability, performance, and code maintainability.

**Key Highlights:**

- **Performance** — Separation of commands and queries, parallel event processing
- **Reliability** — Transaction Outbox for guaranteed event delivery, Saga with compensation support and eventual consistency
- **Flexible Types** — Easy integration with any type: [Pydantic, dataclasses, msgspec, attrs, TypedDict and more](https://mkdocs.python-cqrs.dev/latest/request_response_types/index.md)
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
from cqrs.bootstrap import requests as bootstrap

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

See [Bootstrap](https://mkdocs.python-cqrs.dev/latest/bootstrap/index.md) for detailed setup instructions.
