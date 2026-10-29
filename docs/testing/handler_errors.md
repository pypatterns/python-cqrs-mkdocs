---
title: Handler Errors
description: The command result returns from send; the error is on the handler_errors journal.
---

# Handler Errors

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`send` returns the command result. The error is on `handler_errors`.

See [Runtime Processing](../event_handler/runtime_processing.md).

```python
class AuditHandler(cqrs.EventHandler[OrderCreated]):
    async def handle(self, event: OrderCreated) -> None:
        raise RuntimeError("audit failed")

async def test_domain_handler_error_is_swallowed() -> None:
    container = di.Container()
    async with test_harness(
        container,
        commands_mapper=commands_mapper,
        domain_events_mapper=domain_events_mapper,
    ) as harness:
        result = await harness.mediator.send(CreateOrder(sku="book"))

        assert result.order_id == "1"
        assert harness.handler_errors.of(OrderCreated, AuditHandler)
```

Library example: [`examples/testing/test_domain_and_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_domain_and_notification.py).
