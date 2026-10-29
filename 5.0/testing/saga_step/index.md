# Saga Step

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`act` is on `invocations`. `running_count == 1` inside the loop after a non-final step. After the full `async for`, the saga is completed and `running_count == 0`.

See [Saga Pattern](https://mkdocs.python-cqrs.dev/latest/saga/index.md).

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
