---
title: Event Fallback
description: Assert both classes on the invocations journal.
---

# Event Fallback

Both classes are on `invocations`. The primary handler is entered, then the fallback.

See [Event Handler Fallback](../event_handler/fallback.md).

```python
def domain_events_mapper(mapper: cqrs.EventMap) -> None:
    mapper.bind(
        OrderCreated,
        cqrs.EventHandlerFallback(AuditHandler, AuditFallback),
    )

await harness.mediator.send(CreateOrder(sku="book"))
harness.invocations.assert_entered(AuditHandler)
harness.invocations.assert_entered(AuditFallback)
```

Library example: [`examples/testing/fallback.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/fallback.py).
