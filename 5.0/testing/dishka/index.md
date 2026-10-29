# dishka

The harness does not import dishka. The mediator is already built, and `around` wraps it. Read `invocations`. The harness builder stays unused.

See [DI containers](https://mkdocs.python-cqrs.dev/latest/bootstrap/di_containers/index.md).

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
