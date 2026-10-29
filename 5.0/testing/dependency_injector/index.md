# dependency-injector

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

The harness does not import dependency-injector. The adapter does not implement `SupportsScope`, so `scope_strategy` is not `SEND`. Read `requests`. A shared session on `invocations` stays absent.

See [Dependency injection](https://mkdocs.python-cqrs.dev/latest/di/index.md).

```python
from dependency_injector import containers, providers

from cqrs.container.dependency_injector import DependencyInjectorCQRSContainer

class Container(containers.DeclarativeContainer):
    create_order_handler = providers.Factory(CreateOrderHandler)

async def test_around_records_a_mediator_on_dependency_injector() -> None:
    adapter = DependencyInjectorCQRSContainer()
    adapter.attach_external_container(Container())
    mediator = bootstrap.bootstrap(
        di_container=adapter,
        commands_mapper=commands_mapper,
    )
    async with test_harness.around(mediator) as harness:
        await mediator.send(CreateOrder(sku="book"))

        assert harness.requests.contains(CreateOrder)
```

Library example: [`examples/testing/test_dependency_injector_container.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_dependency_injector_container.py).
