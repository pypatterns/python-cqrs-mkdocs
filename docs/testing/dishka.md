---
title: dishka
description: around wraps a mediator that is already built. The harness does not import dishka.
---

# dishka

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

The harness does not import dishka. The mediator is already built, and `around` wraps it. Read `invocations`. The harness builder stays unused.

See [DI containers](../bootstrap/di_containers.md).

```python
from dishka import Provider, Scope, make_async_container, provide

from cqrs.container.dishka import DishkaCQRSContainer

class AppProvider(Provider):
    create_order_handler = provide(CreateOrderHandler, scope=Scope.REQUEST)

async def test_around_records_a_mediator_on_dishka() -> None:
    container = make_async_container(AppProvider())
    mediator = bootstrap.bootstrap(
        di_container=DishkaCQRSContainer(container),
        commands_mapper=commands_mapper,
        scope_strategy=cqrs.ScopeStrategy.HANDLER,
    )
    async with test_harness.around(mediator) as harness:
        await mediator.send(CreateOrder(sku="book"))

        harness.invocations.assert_entered(CreateOrderHandler)
```

Library example: [`examples/testing/test_dishka_container.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_dishka_container.py).
