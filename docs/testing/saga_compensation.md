---
title: Saga Compensation
description: Assert compensate on the invocations journal and the failed saga status.
---

# Saga Compensation

`compensate` is on `invocations`. The saga status is `FAILED` and the step status is `COMPENSATED`. There is no saga status `compensated`.

See [Compensation Strategy](../saga/compensation.md).

```python
async for step in harness.saga_mediator.execute(OrderContext(order_id="1")):
    pass

assert harness.invocations.of(ReserveStock)[-1].method == "compensate"
saga = harness.sagas.one(OrderSaga)
assert saga.status is SagaStatus.FAILED
assert saga.step_status("ReserveStock") is SagaStepStatus.COMPENSATED
```

Library example: [`examples/testing/saga.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/saga.py).
