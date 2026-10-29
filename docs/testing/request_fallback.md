---
title: Request Fallback
description: Assert both classes on invocations; the requests journal holds the fallback response.
---

# Request Fallback

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

Both classes are on `invocations`. The response on `requests` is the fallback's.

See [Request Handler Fallback](../request_handler/fallback.md).

```python
def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(
        CreateOrder,
        cqrs.RequestHandlerFallback(CreateOrderHandler, CreateOrderFallback),
    )

result = await harness.mediator.send(CreateOrder(sku="book"))
assert result.source == "fallback"
harness.invocations.assert_entered(CreateOrderHandler)
harness.invocations.assert_entered(CreateOrderFallback)
```

Library example: [`examples/testing/fallback.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/fallback.py).
