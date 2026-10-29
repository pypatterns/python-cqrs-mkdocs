---
title: dependency-injector
description: around wraps the mediator. The adapter does not implement SupportsScope, so scope_strategy is not SEND.
---

# dependency-injector

The harness does not import dependency-injector. The adapter does not implement `SupportsScope`, so `scope_strategy` is not `SEND`. Read `requests`. A shared session on `invocations` stays absent.

See [Dependency injection](../di.md).

```python
from cqrs.container.dependency_injector import DependencyInjectorCQRSContainer

mediator = bootstrap.bootstrap(
    di_container=DependencyInjectorCQRSContainer(container),
    commands_mapper=commands_mapper,
)
async with test_harness.around(mediator) as harness:
    await mediator.send(CreateOrder(sku="book"))
    assert harness.requests.contains(CreateOrder)
```

Library example: [`examples/testing/dependency_injector_container.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/dependency_injector_container.py).
