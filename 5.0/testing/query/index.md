# Query

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

A query uses the same `send` as a command. The handler returns the view. After the read, `handled`, `published`, and `outbox` are empty.

See [Request Handlers](https://mkdocs.python-cqrs.dev/latest/request_handler/index.md).

```python
class ReadOrder(cqrs.Request[OrderView]):
    order_id: str

class ReadOrderHandler(cqrs.RequestHandler[ReadOrder]):
    async def handle(self, request: ReadOrder) -> OrderView:
        return OrderView(order_id=request.order_id)

def queries_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(ReadOrder, ReadOrderHandler)

async def test_query_leaves_delivery_journals_empty() -> None:
    container = di.Container()
    async with test_harness(container, queries_mapper=queries_mapper) as harness:
        view = await harness.mediator.send(ReadOrder(order_id="1"))

        assert view.order_id == "1"
        harness.handled.assert_empty()
        harness.published.assert_empty()
        harness.outbox.assert_empty()
```

Library example: [`examples/testing/test_command_and_query.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_command_and_query.py).
