---
title: di container
description: ScopeStrategy.SEND on di.Container shares one session. Pass di.Container, not TestContainer.
---

# di container

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`invocations` holds the command handler and the domain handler. Under `di.Container` and `ScopeStrategy.SEND`, their sessions are the same object. A second session stays absent. `di` is already a core dependency. For `SEND`, pass `di.Container`. `TestContainer` stays unused.

See [Dependency injection](../di.md) and [Scope strategies](../scoped_dependencies/strategies.md).

```python
container = di.Container()
container.bind(di.bind_by_type(di.dependent.Dependent(Session, scope="request"), Session))

async with test_harness(
    container,
    commands_mapper=commands_mapper,
    domain_events_mapper=domain_events_mapper,
    scope_strategy=cqrs.ScopeStrategy.SEND,
) as harness:
    await harness.mediator.send(CreateOrder(sku="book"))
    command_session = harness.invocations.of(CreateOrderHandler)[0].handler_instance.session
    audit_session = harness.invocations.of(AuditHandler)[0].handler_instance.session
    assert command_session is audit_session
```

Library example: [`examples/di/scoped_dependencies_di.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/di/scoped_dependencies_di.py).
