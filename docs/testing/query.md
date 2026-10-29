---
title: Query
description: After a read, the handled, published, and outbox journals are empty.
---

# Query

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

A query uses the same `send` as a command. The handler returns the view. After the read, `handled`, `published`, and `outbox` are empty.

See [Request Handlers](../request_handler/index.md).

```python
class ReadOrder(cqrs.Request[OrderView]):
    order_id: str

class ReadOrderHandler(cqrs.RequestHandler[ReadOrder]):
    async def handle(self, request: ReadOrder) -> OrderView:
        return OrderView(order_id=request.order_id)

view = await harness.mediator.send(ReadOrder(order_id="1"))
assert view.order_id == "1"
harness.handled.assert_empty()
harness.published.assert_empty()
harness.outbox.assert_empty()
```

Library example: [`examples/testing/command_and_query.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/command_and_query.py).
