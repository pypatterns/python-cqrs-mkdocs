# Best Practices

- **Back to Transactional Outbox Overview**

  Return to the Transactional Outbox overview page with all topics.

  [Back to Overview](https://vadikko2.github.io/python-cqrs-mkdocs/outbox/index.md)

______________________________________________________________________

## Overview

1. **Always commit** — Always call `commit()` after adding events
1. **Use transactions** — Ensure outbox operations are in the same transaction as business logic
1. **Register events** — Register all event types in `OutboxedEventMap`
1. **Handle failures** — Implement retry logic in the publisher process
1. **Monitor status** — Track `NOT_PRODUCED` events for debugging
1. **Use compression** — Enable compression for large payloads
1. **Batch processing** — Process events in batches for efficiency
1. [**Event Producing**](https://vadikko2.github.io/python-cqrs-mkdocs/event_producing/index.md) — How to produce events without outbox
1. [**FastStream Integration**](https://vadikko2.github.io/python-cqrs-mkdocs/faststream/index.md) — Kafka and RabbitMQ message broker configuration
1. [**Dependency Injection**](https://vadikko2.github.io/python-cqrs-mkdocs/di/index.md) — How to inject outbox repository
