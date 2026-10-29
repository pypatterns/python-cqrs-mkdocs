# Saga Recovery

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`harness.sagas.recover` resumes the stored saga. A finished step does not enter `act` a second time.

See [Saga Recovery & Eventual Consistency](https://mkdocs.python-cqrs.dev/latest/saga/recovery/index.md).

Arrange stops the saga after the first step. Act recovers it.

```python
async def test_recovery_does_not_repeat_a_finished_step() -> None:
    container = di.Container()
    async with test_harness(container, sagas_mapper=sagas_mapper) as harness:
        async for step in harness.saga_mediator.execute(OrderContext(order_id="1")):
            if step.step_type is ReserveStock:
                break
        saga_id = harness.sagas.one(OrderSaga).saga_id

        await harness.sagas.recover(OrderSaga(), saga_id, OrderContext)

        acts = [item for item in harness.invocations.of(ReserveStock) if item.method == "act"]
        assert len(acts) == 1
        assert harness.sagas.one(OrderSaga).status is SagaStatus.COMPLETED
```

Library example: [`examples/testing/test_saga.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_saga.py).
