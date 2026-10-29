---
title: Saga Fallback
description: Assert both classes on the invocations journal; the saga stays completed.
---

# Saga Fallback

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

Both classes are on `invocations`. The last method of `ReserveStock` is `act`, not `compensate`, and the saga is `COMPLETED`. This is not compensation.

See [Saga Fallback Pattern](../saga/fallback/index.md).

```python
class OrderSaga(cqrs.Saga[OrderContext]):
    steps = [
        cqrs.saga.fallback.Fallback(step=ReserveStock, fallback=ReserveStockFallback),
        ChargeCard,
    ]

async for step in harness.saga_mediator.execute(OrderContext(order_id="1")):
    pass

harness.invocations.assert_entered(ReserveStock)
harness.invocations.assert_entered(ReserveStockFallback)
assert harness.invocations.of(ReserveStock)[-1].method == "act"
assert harness.sagas.one(OrderSaga).status is SagaStatus.COMPLETED
```

Library example: [`examples/testing/saga.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/saga.py).
