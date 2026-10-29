---
title: Event Mediator
description: Assert the handler on the invocations journal, method handle.
---

# Event Mediator

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`invocations` records the handler, and the method is `handle`. `EventMediator` goes through `EventDispatcher`, not `EventEmitter`, so this is not the `handled` journal.

See [Event Mediator](../bootstrap/event_mediator.md).

```python
await harness.event_mediator.send(OrderCreated(order_id="1"))
harness.invocations.assert_entered(AuditHandler)
assert harness.invocations.of(AuditHandler)[0].method == "handle"
```

Library example: [`examples/testing/event_mediator.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/event_mediator.py).
