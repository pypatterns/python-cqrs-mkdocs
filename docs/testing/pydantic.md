---
title: Pydantic requests
description: ValidationError is raised by the constructor, before send. A valid send returns the response.
---

# Pydantic requests

`ValidationError` is raised by the constructor, before `send`, so that attempt leaves `requests` empty. A valid `send` returns the response. Mark the test `pydantic`.

See [Pydantic](../request_response_types/pydantic.md).

```python
class CreateOrder(cqrs.PydanticRequest[CreatedOrder]):
    sku: str = pydantic.Field(min_length=1)

with pytest.raises(pydantic.ValidationError):
    CreateOrder(sku="")

result = await harness.mediator.send(CreateOrder(sku="book"))
assert result.order_id == "1"
```

Library example: [`examples/testing/pydantic_request.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/pydantic_request.py).
