# Pydantic requests

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`ValidationError` is raised by the constructor, before `send`, so that attempt leaves `requests` empty. A valid `send` returns the response. Mark the test `pydantic`.

See [Pydantic](https://mkdocs.python-cqrs.dev/latest/request_response_types/pydantic/index.md).

```python
pytestmark = pytest.mark.pydantic

class CreateOrder(cqrs.PydanticRequest[CreatedOrder]):
    sku: str = pydantic.Field(min_length=1)

def test_empty_sku_fails_before_send() -> None:
    sku = ""

    with pytest.raises(pydantic.ValidationError):
        CreateOrder(sku=sku)

async def test_valid_request_returns_the_response() -> None:
    container = di.Container()
    async with test_harness(container, commands_mapper=commands_mapper) as harness:
        result = await harness.mediator.send(CreateOrder(sku="book"))

        assert result.order_id == "1"
```

Library example: [`examples/testing/test_pydantic_request.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_pydantic_request.py).
