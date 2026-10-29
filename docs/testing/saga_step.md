---
title: Saga Step
description: Assert act on the invocations journal and the running saga count.
---

# Saga Step

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`act` is on `invocations`. `running_count == 1` inside the loop after a non-final step. After the full `async for`, the saga is completed and `running_count == 0`.

See [Saga Pattern](../saga/index.md).

```python
async for step in harness.saga_mediator.execute(OrderContext(order_id="1")):
    if step.step_type is ReserveStock:
        assert harness.sagas.running_count == 1
        assert harness.invocations.of(ReserveStock)[0].method == "act"

assert harness.sagas.running_count == 0
assert harness.sagas.completed_count == 1
saga = harness.sagas.one(OrderSaga)
assert saga.completed_steps == ["ReserveStock", "ChargeCard"]
```

Library example: [`examples/testing/saga.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/saga.py).
