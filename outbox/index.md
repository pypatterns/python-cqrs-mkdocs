# Transactional Outbox

The Transactional Outbox pattern ensures reliable event publishing by storing events in a database table within the same transaction as business logic. This guarantees that events are persisted even if the system crashes before they can be published to a message broker.

## Overview

- **Implementation**

  Interface and SQLAlchemy implementation for transactional outbox.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/outbox/implementation/index.md)

- **Database Support**

  Supported databases, dialect-specific DDL, Alembic setup and custom dialects.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/outbox/databases/index.md)

- **Usage**

  Event registration and publishing with at-least-once delivery guarantees.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/outbox/usage/index.md)

- **Examples**

  Complete examples of transactional outbox pattern.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/outbox/examples/index.md)

- **Best Practices**

  Best practices and recommendations for reliable event delivery.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/outbox/best_practices/index.md)

The Transactional Outbox pattern solves the problem of ensuring event delivery in distributed systems. When a command handler processes a request and generates events, those events need to be published to a message broker. However, if the system crashes between processing the command and publishing the event, the event can be lost.

The Outbox pattern solves this by:

| Step                          | Description                                                                   | Benefit                |
| ----------------------------- | ----------------------------------------------------------------------------- | ---------------------- |
| **1. Store in Database**      | Events are saved to an outbox table in the same transaction as business logic | Guaranteed persistence |
| **2. Separate Publishing**    | A background process reads from the outbox and publishes events               | Decoupled publishing   |
| **3. At-least-once Delivery** | Events are only removed from outbox after successful publishing               | Reliable delivery      |

Prerequisites

Understanding of [Event Handling](https://vadikko2.github.io/python-cqrs-mkdocs/event_handler/index.md) is required. The Outbox pattern ensures reliable delivery of events that are emitted by command handlers.

Related Topics

- [Event Producing](https://vadikko2.github.io/python-cqrs-mkdocs/event_producing/index.md) — For configuring message brokers
- [FastStream Integration](https://vadikko2.github.io/python-cqrs-mkdocs/faststream/index.md) — For consuming events from message brokers
- [Bootstrap](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/index.md) — For configuring outbox in bootstrap process

## Why Use Transactional Outbox?

### The Problem

Without the Outbox pattern, event publishing can fail:

```
sequenceDiagram
    participant Handler as Command Handler
    participant DB as Database
    participant Broker as Message Broker

    Handler->>DB: Process Command & Commit
    Handler->>Broker: Publish Event
    Note over Handler,Broker: ❌ System Crashes<br/>Event Lost!
```

### The Solution

With the Outbox pattern, events are safely stored:

```
sequenceDiagram
    participant Handler as Command Handler
    participant DB as Database
    participant Outbox as Outbox Table
    participant Publisher as Publisher Process
    participant Broker as Message Broker

    Handler->>DB: Process Command
    Handler->>Outbox: Save Event (same transaction)
    Handler->>DB: Commit Transaction
    Note over Handler,Outbox: ✅ System Crashes<br/>Event Safe in Outbox!

    Publisher->>Outbox: Read Events
    Publisher->>Broker: Publish Events
    Publisher->>Outbox: Update Status
```

## Pattern Flow

The Transactional Outbox pattern follows this flow:

```
sequenceDiagram
    participant Handler as Command Handler
    participant DB as Database
    participant Outbox as Outbox Table
    participant Publisher as Event Publisher
    participant Broker as Message Broker

    Handler->>DB: 1. Process Business Logic
    Handler->>Outbox: 2. Save Events (same transaction)
    Handler->>DB: 3. Commit Transaction
    Note over DB,Outbox: Events safely stored

    Publisher->>Outbox: 4. Read Events (batch)
    Publisher->>Broker: 5. Publish Events
    Publisher->>Outbox: 6. Update Status (PRODUCED)
    Publisher->>DB: 7. Commit Transaction
```

### Detailed Flow Diagram

```
graph TD
    A[Command Handler] -->|1. Process Command| B[Business Logic]
    B -->|2. Generate Events| C[Create Events]
    C -->|3. Save to Outbox| D[Outbox Table]
    B -->|Same Transaction| D
    D -->|4. Commit| E[Transaction Committed]

    E -->|Events Stored| F[Event Publisher Process]
    F -->|5. Read Batch| D
    D -->|6. Return Events| F
    F -->|7. Publish| G[Message Broker]
    G -->|8. Success| F
    F -->|9. Update Status| D
    F -->|10. Commit| E

    style D fill:#e1f5ff
    style E fill:#c8e6c9
    style G fill:#fff3e0
```
