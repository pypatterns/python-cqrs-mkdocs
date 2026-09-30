# Bootstrap

## Overview

- **Request Mediator**

  Standard mediator for commands and queries with automatic handler resolution.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/request_mediator/index.md)

- **Streaming Request Mediator**

  For incremental processing and Server-Sent Events (SSE) support.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/streaming_mediator/index.md)

- **Event Mediator**

  For processing events from message brokers like Kafka and RabbitMQ.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/event_mediator/index.md)

- **Saga Mediator**

  Orchestrated sagas with step streaming, storage, and recovery.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/saga_mediator/index.md)

- **Message Brokers**

  Configure Kafka, RabbitMQ, and custom brokers for event publishing.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/message_brokers/index.md)

- **Middlewares**

  Request interception and modification with custom middleware support.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/middlewares/index.md)

- **DI Containers**

  Dependency injection configuration and container setup.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/di_containers/index.md)

- **Advanced Configuration**

  Combining all options and manual setup for complex scenarios.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/advanced/index.md)

The `bootstrap` utilities simplify the initial configuration of your CQRS application. They automatically set up:

- **Dependency Injection Container** — Resolves handlers and their dependencies (see [Dependency Injection](https://vadikko2.github.io/python-cqrs-mkdocs/di/index.md))
- **Request Mapping** — Maps commands and queries to their handlers (see [Request Handlers](https://vadikko2.github.io/python-cqrs-mkdocs/request_handler/index.md))
- **Event Mapping** — Maps domain events to their handlers (see [Event Handling](https://vadikko2.github.io/python-cqrs-mkdocs/event_handler/index.md))
- **Saga Mapping** — Maps saga context types to saga classes (see [Saga Pattern](https://vadikko2.github.io/python-cqrs-mkdocs/saga/index.md))
- **Message Broker** — Configures event publishing (see [Event Producing](https://vadikko2.github.io/python-cqrs-mkdocs/event_producing/index.md))
- **Middlewares** — Adds logging and custom middlewares
- **Event Processing** — Configures parallel event processing

Getting Started

If you're new to `python-cqrs`, start here! Bootstrap is the foundation for all other features. After configuring bootstrap, proceed to [Request Handlers](https://vadikko2.github.io/python-cqrs-mkdocs/request_handler/index.md) to learn how to create command and query handlers.

Navigation

Use the navigation menu on the left to explore different mediator types and configuration options. Each section covers a specific aspect of bootstrap configuration.

## Mediator Types

The `python-cqrs` package provides four types of mediators:

| Mediator Type                  | Use Case                                            | Bootstrap Function                              |
| ------------------------------ | --------------------------------------------------- | ----------------------------------------------- |
| **`RequestMediator`**          | Standard commands and queries                       | `cqrs.requests.bootstrap.bootstrap()`           |
| **`StreamingRequestMediator`** | Streaming requests with incremental results         | `cqrs.requests.bootstrap.bootstrap_streaming()` |
| **`EventMediator`**            | Processing events from message brokers              | `cqrs.events.bootstrap.bootstrap()`             |
| **`SagaMediator`**             | Orchestrated sagas with step streaming and recovery | `cqrs.saga.bootstrap.bootstrap()`               |

Mediator Comparison

Each mediator type has its own bootstrap function and configuration options. Choose based on your use case:

- **RequestMediator**: Most common, handles standard CQRS operations
- **StreamingRequestMediator**: For real-time progress updates (SSE, WebSockets)
- **EventMediator**: For consuming events from Kafka/RabbitMQ
- **SagaMediator**: For distributed transactions with steps and compensation

**When to use each mediator?**

- **RequestMediator**: Use for standard HTTP API endpoints (GET, POST, PUT, DELETE)
- **StreamingRequestMediator**: Use when you need to stream results back to clients (file processing, batch operations)
- **EventMediator**: Use in FastStream consumers to process events from message brokers
- **SagaMediator**: Use when coordinating multiple steps across services with automatic compensation on failure

## Quick Navigation

- **[Request Mediator](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/request_mediator/index.md)** — Standard mediator for commands and queries
- **[Streaming Request Mediator](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/streaming_mediator/index.md)** — For incremental processing and SSE
- **[Event Mediator](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/event_mediator/index.md)** — For processing events from message brokers
- **[Saga Mediator](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/saga_mediator/index.md)** — Orchestrated sagas with storage and recovery
- **[Message Brokers](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/message_brokers/index.md)** — Kafka, RabbitMQ, and custom brokers
- **[Middlewares](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/middlewares/index.md)** — Request interception and modification
- **[DI Containers](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/di_containers/index.md)** — Dependency injection configuration
- **[Advanced Configuration](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/advanced/index.md)** — Combining all options and manual setup
