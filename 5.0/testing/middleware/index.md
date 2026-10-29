# Middleware

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`middlewares.of(...).called_next` is `False` when the middleware does not call `handle`. `invocations` does not contain the handler. `requests` holds the middleware response.

See [Middlewares](https://mkdocs.python-cqrs.dev/latest/bootstrap/middlewares/index.md).

```python
class DenyMiddleware:
    async def __call__(self, request, handle):
        return CreatedOrder(order_id="denied")

async with test_harness(container, commands_mapper=commands_mapper, middlewares=[DenyMiddleware()]) as harness:
    result = await harness.mediator.send(CreateOrder(sku="book"))
    assert result.order_id == "denied"
    harness.invocations.assert_not_entered(CreateOrderHandler)
    assert harness.middlewares.of(DenyMiddleware)[0].called_next is False
```

Library example: [`examples/testing/middleware.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/middleware.py).
