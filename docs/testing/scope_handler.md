---
title: Scope HANDLER and NONE
description: Assert both handlers on the invocations journal; order is not checked.
---

# Scope HANDLER and NONE

Both handlers are in the set of `invocations`. Order is not asserted. `HANDLER` and `NONE` allow the parallel flag.

See [Scope Strategies](../scoped_dependencies/strategies.md).

```python
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

Library example: [`examples/testing/parallel_handlers.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/parallel_handlers.py).
