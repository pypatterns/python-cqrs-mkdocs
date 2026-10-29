---
title: Event Fallback
description: Assert both classes on the invocations journal.
---

# Event Fallback

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

Both classes are on `invocations`. The primary handler is entered, then the fallback.

See [Event Handler Fallback](../event_handler/fallback.md).

```python
def domain_events_mapper(mapper: cqrs.EventMap) -> None:
    mapper.bind(
        OrderCreated,
        cqrs.EventHandlerFallback(AuditHandler, AuditFallback),
    )

async def test_event_fallback_runs_after_the_primary_fails() -> None:
    container = di.Container()
    async with test_harness(
        container,
        commands_mapper=commands_mapper,
        domain_events_mapper=domain_events_mapper,
    ) as harness:
        await harness.mediator.send(CreateOrder(sku="book"))

        harness.invocations.assert_entered(AuditHandler)
        harness.invocations.assert_entered(AuditFallback)
```

Library example: [`examples/testing/test_fallback.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_fallback.py).
