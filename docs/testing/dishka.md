---
title: dishka
description: around wraps a mediator that is already built. The harness does not import dishka.
---

# dishka

The harness does not import dishka. The mediator is already built, and `around` wraps it. Read `invocations`. The harness builder stays unused.

See [DI containers](../bootstrap/di_containers.md).

```python
from cqrs.container.dishka import DishkaCQRSContainer

mediator = bootstrap.bootstrap(
    di_container=DishkaCQRSContainer(container),
    commands_mapper=commands_mapper,
    scope_strategy=cqrs.ScopeStrategy.HANDLER,
)
async with test_harness.around(mediator) as harness:
    await mediator.send(CreateOrder(sku="book"))
    harness.invocations.assert_entered(CreateOrderHandler)
```

Library example: [`examples/testing/dishka_container.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/dishka_container.py).
