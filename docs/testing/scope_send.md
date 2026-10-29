---
title: Scope SEND
description: Assert invocation order on the invocations journal under ScopeStrategy.SEND.
---

# Scope SEND

Under `ScopeStrategy.SEND`, `invocations` for argument type `OrderCreated` are `AuditHandler`, then `SearchHandler`.

See [Scope Strategies](../scoped_dependencies/strategies.md).

```python
async with test_harness(
    di_container,
    commands_mapper=commands_mapper,
    domain_events_mapper=domain_events_mapper,
    scope_strategy=cqrs.ScopeStrategy.SEND,
) as harness:
    await harness.mediator.send(CreateOrder(sku="book"))
    entered = [item.handler for item in harness.invocations if item.argument_type is OrderCreated]
    assert entered == [AuditHandler, SearchHandler]
```

Library example: [`examples/testing/parallel_handlers.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/parallel_handlers.py).
