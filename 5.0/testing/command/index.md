# Command

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`requests` records the command and the result `send` returns. `invocations` records the handler that entered `handle`. `published` stays empty unless a notification is also emitted.

See [Request Handlers](https://mkdocs.python-cqrs.dev/latest/request_handler/index.md).

```python
class CreateOrder(cqrs.Request[CreatedOrder]):
    sku: str

class CreateOrderHandler(cqrs.RequestHandler[CreateOrder]):
    def __init__(self) -> None:
        self._events: list[cqrs.Event] = []

    @property
    def events(self) -> list[cqrs.Event]:
        return self._events

    async def handle(self, request: CreateOrder) -> CreatedOrder:
        self._events.append(OrderCreated(order_id="1"))
        return CreatedOrder(order_id="1")

def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(CreateOrder, CreateOrderHandler)

async def test_command_is_on_requests_and_invocations() -> None:
    container = di.Container()
    async with test_harness(container, commands_mapper=commands_mapper) as harness:
        result = await harness.mediator.send(CreateOrder(sku="book"))

        assert result.order_id == "1"
        assert harness.requests.contains(CreateOrder)
        harness.invocations.assert_entered(CreateOrderHandler)
```

Library example: [`examples/testing/test_command_and_query.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_command_and_query.py).
