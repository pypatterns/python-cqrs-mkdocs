# Dataclass requests

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`requests.of(...).response` is the object `send` returned. The harness adds no validator, so no validation record sits beside `requests`. This is the default path.

See [Dataclasses](https://mkdocs.python-cqrs.dev/latest/request_response_types/dataclasses/index.md).

```python
await harness.mediator.send(CreateOrder(sku="book"))
assert harness.requests.of(CreateOrder)[0].response == CreatedOrder(order_id="1")
```

Library example: [`examples/testing/command_and_query.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/command_and_query.py).
