# Event Handling

## Overview

- **Event Flow**

  Understanding how events flow through the system from handlers to processing.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/event_handler/event_flow/index.md)

- **Runtime Processing**

  How events are processed synchronously in the same request context.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/event_handler/runtime_processing/index.md)

- **Parallel Processing**

  Configuring parallel event processing with concurrency limits.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/event_handler/parallel_processing/index.md)

- **Event Types**

  DomainEvent vs NotificationEvent and when to use each type.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/event_handler/event_types/index.md)

- **Examples**

  Complete examples of event handling patterns.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/event_handler/examples/index.md)

- **Best Practices**

  Best practices and recommendations for event handling.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/event_handler/best_practices/index.md)

- **Fallback**

  Fallback handler when primary event handler fails or circuit breaker is open.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/event_handler/fallback/index.md)

Event handlers process domain events that are emitted from command handlers. These events represent something that happened in the domain and trigger side effects like sending notifications, updating read models, or triggering other workflows.

When a command handler processes a request, it can emit domain events through the `events` property. These events are automatically collected and processed by event handlers registered in the system. **Event handlers** can in turn produce **follow-up events** via their own `events` property; these follow-ups are processed in the same pipeline (sequential BFS or parallel with semaphore), enabling multi-level event chains.

| Aspect                 | Description                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Runtime Processing** | Events are processed synchronously in the same request context, not asynchronously                      |
| **Automatic Dispatch** | Events are automatically dispatched to registered handlers after command execution                      |
| **Event Propagation**  | Handlers can return follow-up events via `events`; they are processed in the same run (BFS or parallel) |
| **Parallel Support**   | Multiple events can be processed in parallel with configurable concurrency limits                       |
| **Side Effects**       | Event handlers perform side effects without blocking the main command flow                              |

Prerequisites

Understanding of [Request Handlers](https://vadikko2.github.io/python-cqrs-mkdocs/request_handler/index.md) and [Bootstrap](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/index.md) is required. Events are emitted by command handlers and processed by event handlers.

Related Topics

- [Transaction Outbox](https://vadikko2.github.io/python-cqrs-mkdocs/outbox/index.md) — For reliable event delivery to message brokers
- [Event Producing](https://vadikko2.github.io/python-cqrs-mkdocs/event_producing/index.md) — For publishing events to Kafka/RabbitMQ
- [FastStream Integration](https://vadikko2.github.io/python-cqrs-mkdocs/faststream/index.md) — For consuming events from message brokers
