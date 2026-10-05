# Best Practices

- **Back to Transactional Outbox Overview**

  Return to the Transactional Outbox overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/outbox/index.md)

______________________________________________________________________

## Overview

1. **Always commit** — Always call `commit()` after adding events (including after `get_many` / publish loops)
1. **Use transactions** — Ensure outbox operations are in the same transaction as business logic
1. **Register events** — Register all event types on an `OutboxedEventMap` (prefer an isolated instance)
1. **Handle failures** — Implement retry logic in the publisher process
1. **Monitor status** — Track `NOT_PRODUCED` events for debugging. Rows that fail to deserialize (or whose `event_name` is not registered) are marked `NOT_PRODUCED` and spend the same `flush_counter` budget as broker publish failures, so they stop filling the selectable batch after the limit
1. **Use compression** — Enable compression for large payloads
1. **Batch processing** — Process events in batches for efficiency
1. **Codecs** — Keep JSON as the default; register Protobuf (or a custom `EventCodec`) only per event that needs it. Changing a codec for an already-registered name does not rewrite pending rows — keep the reader compatible with bytes already stored, or drain the outbox first
1. [**Event Producing**](https://mkdocs.python-cqrs.dev/latest/event_producing/index.md) — How to produce events without outbox
1. [**FastStream Integration**](https://mkdocs.python-cqrs.dev/latest/faststream/index.md) — Kafka and RabbitMQ message broker configuration
1. [**Dependency Injection**](https://mkdocs.python-cqrs.dev/latest/di/index.md) — How to inject outbox repository
1. [**Protobuf Integration**](https://mkdocs.python-cqrs.dev/latest/protobuf/index.md) — Opt-in Protobuf codecs for outbox and brokers
