# Mixed Usage

You can mix different types for requests and responses based on your needs. This flexibility allows you to choose the best type for each use case.

## Examples

### Pydantic Request with Dataclass Response

Use Pydantic for request validation, but lightweight dataclass for response:

```python
import dataclasses
import cqrs
import pydantic

# Pydantic request with validation
class CreateOrderCommand(cqrs.PydanticRequest):
    user_id: str
    product_id: str
    quantity: int = pydantic.Field(gt=0)

# Dataclass response - lightweight
@dataclasses.dataclass
class OrderResponse(cqrs.DCResponse):
    order_id: str
    total_price: float

class CreateOrderHandler(
    cqrs.RequestHandler[CreateOrderCommand, OrderResponse]
):
    @property
    def events(self) -> list[cqrs.IEvent]:
        return []

    async def handle(self, request: CreateOrderCommand) -> OrderResponse:
        # Request is validated by Pydantic
        total_price = 99.99 * request.quantity
        return OrderResponse(
            order_id=f"order_{request.user_id}",
            total_price=total_price
        )
```

### Dataclass Request with Pydantic Response

Use lightweight dataclass for request, but Pydantic for response validation:

```python
@dataclasses.dataclass
class GetUserQuery(cqrs.DCRequest):
    """Dataclass query - simple and lightweight."""
    user_id: str

class UserDetailsResponse(cqrs.PydanticResponse):
    """Pydantic response with validation."""
    user_id: str
    username: str
    email: str
    total_orders: int = 0

class GetUserQueryHandler(
    cqrs.RequestHandler[GetUserQuery, UserDetailsResponse]
):
    @property
    def events(self) -> list[cqrs.IEvent]:
        return []

    async def handle(self, request: GetUserQuery) -> UserDetailsResponse:
        # Response is validated by Pydantic
        return UserDetailsResponse(
            user_id=request.user_id,
            username="john",
            email="john@example.com",
            total_orders=5
        )
```

### Msgspec Request with Dataclass Response

High-performance request with lightweight response:

```python
import msgspec

class ProcessDataRequest(cqrs.IRequest, msgspec.Struct):
    data: str
    options: dict

    def to_dict(self) -> dict:
        return msgspec.to_builtins(self)

    @classmethod
    def from_dict(cls, **kwargs) -> Self:
        return msgspec.from_builtins(cls, kwargs)

@dataclasses.dataclass
class ProcessDataResponse(cqrs.DCResponse):
    result: str
    processed_at: str
```

## Best Practices for Mixed Usage

1. **Validate Input, Optimize Output**
1. Use Pydantic/Msgspec for requests (external input)
1. Use Dataclasses for responses (internal data)
1. **Performance-Critical Paths**
1. Use Msgspec for high-throughput requests
1. Use Dataclasses for simple responses
1. **Consistency Within Domains**
1. Keep the same type for related requests/responses
1. Document your choices in team guidelines
1. **Migration Strategy**
1. Start with one type, migrate gradually
1. All types implement the same interface

## See Also

- [Best Practices](https://vadikko2.github.io/python-cqrs-mkdocs/request_response_types/best_practices/index.md) - Recommendations for choosing types
- [Request Handlers](https://vadikko2.github.io/python-cqrs-mkdocs/request_handler/index.md) - Learn about handler implementation
