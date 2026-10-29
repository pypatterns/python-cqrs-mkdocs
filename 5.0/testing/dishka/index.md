# dishka

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

The harness does not import dishka. The mediator is already built, and `around` wraps it. Read `invocations`. The harness builder stays unused.

See [DI containers](https://mkdocs.python-cqrs.dev/latest/bootstrap/di_containers/index.md).

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
