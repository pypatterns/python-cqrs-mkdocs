---
title: Handler Errors
description: The command result returns from send; the error is on the handler_errors journal.
---

# Handler Errors

`send` returns the command result. The error is on `handler_errors`.

See [Runtime Processing](../event_handler/runtime_processing.md).

```python
result = await harness.mediator.send(CreateOrder(sku="book"))
assert result.order_id == "1"
assert harness.handler_errors.of(OrderCreated, AuditHandler)
```

Library example: [`examples/testing/domain_and_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/domain_and_notification.py).
