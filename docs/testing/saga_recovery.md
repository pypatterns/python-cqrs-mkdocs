---
title: Saga Recovery
description: Recover through the sagas journal; a finished step does not act again.
---

# Saga Recovery

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`harness.sagas.recover` resumes the stored saga. A finished step does not enter `act` a second time.

See [Saga Recovery & Eventual Consistency](../saga/recovery.md).

```python
saga_id = harness.sagas.one(OrderSaga).saga_id
await harness.sagas.recover(OrderSaga(), saga_id, OrderContext)
acts = [item for item in harness.invocations.of(ReserveStock) if item.method == "act"]
assert len(acts) == 1
assert harness.sagas.one(OrderSaga).status is SagaStatus.COMPLETED
```

Library example: [`examples/testing/saga.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/saga.py).
