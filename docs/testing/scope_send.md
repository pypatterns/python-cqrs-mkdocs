---
title: Scope SEND
description: Assert invocation order on the invocations journal under ScopeStrategy.SEND.
---

# Scope SEND

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

Under `ScopeStrategy.SEND`, `invocations` for argument type `OrderCreated` are `AuditHandler`, then `SearchHandler`.

See [Scope Strategies](../scoped_dependencies/strategies.md).

```python
async def test_scope_send_runs_handlers_in_order() -> None:
    container = di.Container()
    async with test_harness(
        container,
        commands_mapper=commands_mapper,
        domain_events_mapper=domain_events_mapper,
        scope_strategy=cqrs.ScopeStrategy.SEND,
    ) as harness:
        await harness.mediator.send(CreateOrder(sku="book"))

        entered = [item.handler for item in harness.invocations if item.argument_type is OrderCreated]
        assert entered == [AuditHandler, SearchHandler]
```

Library example: [`examples/testing/test_parallel_handlers.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_parallel_handlers.py).
