---
title: Domain Event
description: Assert the domain event on the handled and invocations journals.
---

# Domain Event

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`handled` records the domain event and the follow-up event. `invocations` records each handler that entered `handle`. `published` stays empty.

See [Event Handling](../event_handler/index.md).

```python
class OrderCreated(cqrs.DomainEvent):
    order_id: str

class AuditHandler(cqrs.EventHandler[OrderCreated]):
    @property
    def events(self) -> list[cqrs.Event]:
        return [InvoiceRequested(order_id="1")]

    async def handle(self, event: OrderCreated) -> None:
        return None

def domain_events_mapper(mapper: cqrs.EventMap) -> None:
    mapper.bind(OrderCreated, AuditHandler)
    mapper.bind(InvoiceRequested, InvoiceHandler)

async def test_domain_event_and_follow_up_are_handled() -> None:
    container = di.Container()
    async with test_harness(
        container,
        commands_mapper=commands_mapper,
        domain_events_mapper=domain_events_mapper,
    ) as harness:
        await harness.mediator.send(CreateOrder(sku="book"))

        assert harness.handled.contains(OrderCreated)
        assert harness.handled.contains(InvoiceRequested)
        harness.invocations.assert_entered(AuditHandler)
        harness.invocations.assert_entered(InvoiceHandler)
        harness.published.assert_empty()
```

Library example: [`examples/testing/test_domain_and_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_domain_and_notification.py).
