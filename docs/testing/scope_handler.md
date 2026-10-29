---
title: Scope HANDLER and NONE
description: Assert both handlers on the invocations journal; order is not checked.
---

# Scope HANDLER and NONE

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

Both handlers are in the set of `invocations`. Order is not asserted. `HANDLER` and `NONE` allow the parallel flag.

See [Scope Strategies](../scoped_dependencies/strategies.md).

```python
async def test_scope_none_enters_both_handlers_in_any_order() -> None:
    container = di.Container()
    async with test_harness(
        container,
        commands_mapper=commands_mapper,
        domain_events_mapper=domain_events_mapper,
        concurrent_event_handle_enable=True,
        scope_strategy=cqrs.ScopeStrategy.NONE,
    ) as harness:
        await harness.mediator.send(CreateOrder(sku="book"))

        handlers = {item.handler for item in harness.invocations if item.argument_type is OrderCreated}
        assert handlers == {AuditHandler, SearchHandler}
```

Library example: [`examples/testing/test_parallel_handlers.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_parallel_handlers.py).
