# Best Practices

<div class="grid cards" markdown>

-   :material-home: **Back to Transactional Outbox Overview**

    Return to the Transactional Outbox overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

---

## Overview


1. **Always commit** — Always call `commit()` after adding events
2. **Use transactions** — Ensure outbox operations are in the same transaction as business logic
3. **Register events** — Register all event types on an `OutboxedEventMap` (prefer an isolated instance)
4. **Handle failures** — Implement retry logic in the publisher process
5. **Monitor status** — Track `NOT_PRODUCED` events for debugging
6. **Use compression** — Enable compression for large payloads
7. **Batch processing** — Process events in batches for efficiency
8. **Codecs** — Keep JSON as the default; register Protobuf (or a custom `EventCodec`) only per event that needs it


- [**Event Producing**](../event_producing.md) — How to produce events without outbox
- [**FastStream Integration**](../faststream.md) — Kafka and RabbitMQ message broker configuration
- [**Dependency Injection**](../di.md) — How to inject outbox repository
- [**Protobuf Integration**](../protobuf.md) — Opt-in Protobuf codecs for outbox and brokers
