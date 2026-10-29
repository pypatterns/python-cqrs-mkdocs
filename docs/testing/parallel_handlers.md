---
title: Parallel Handlers
description: Assert both handler classes on the invocations journal.
---

# Parallel Handlers

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

Both handler classes are on `invocations`. Do not assert their order.

See [Parallel Event Processing](../event_handler/parallel_processing.md).

```python
def domain_events_mapper(mapper: cqrs.EventMap) -> None:
    mapper.bind(OrderCreated, AuditHandler)
    mapper.bind(OrderCreated, SearchHandler)

async def test_parallel_handlers_both_enter() -> None:
    container = di.Container()
    async with test_harness(
        container,
        commands_mapper=commands_mapper,
        domain_events_mapper=domain_events_mapper,
        concurrent_event_handle_enable=True,
        scope_strategy=cqrs.ScopeStrategy.HANDLER,
    ) as harness:
        await harness.mediator.send(CreateOrder(sku="book"))

        harness.invocations.assert_entered(AuditHandler)
        harness.invocations.assert_entered(SearchHandler)
```

Library example: [`examples/testing/test_parallel_handlers.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_parallel_handlers.py).
