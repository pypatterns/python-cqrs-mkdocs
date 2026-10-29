# Handler Errors

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`send` returns the command result. The error is on `handler_errors`.

See [Runtime Processing](https://mkdocs.python-cqrs.dev/latest/event_handler/runtime_processing/index.md).

```python
result = await harness.mediator.send(CreateOrder(sku="book"))
assert result.order_id == "1"
assert harness.handler_errors.of(OrderCreated, AuditHandler)
```

Library example: [`examples/testing/domain_and_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/domain_and_notification.py).
