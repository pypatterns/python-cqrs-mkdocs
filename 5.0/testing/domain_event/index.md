# Domain Event

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`handled` records the domain event and the follow-up event. `invocations` records each handler that entered `handle`. `published` stays empty.

See [Event Handling](https://mkdocs.python-cqrs.dev/latest/event_handler/index.md).

```python
class OrderCreated(cqrs.DomainEvent):
    order_id: str

class AuditHandler(cqrs.EventHandler[OrderCreated]):
    @property
    def events(self) -> list[cqrs.Event]:
        return [InvoiceRequested(order_id="1")]

    async def handle(self, event: OrderCreated) -> None:
        return None

await harness.mediator.send(CreateOrder(sku="book"))
assert harness.handled.contains(OrderCreated)
assert harness.handled.contains(InvoiceRequested)
harness.invocations.assert_entered(AuditHandler)
harness.invocations.assert_entered(InvoiceHandler)
harness.published.assert_empty()
```

Library example: [`examples/testing/domain_and_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/domain_and_notification.py).
