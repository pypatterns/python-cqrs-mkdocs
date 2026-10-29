# Saga Compensation

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`compensate` is on `invocations`. The saga status is `FAILED` and the step status is `COMPENSATED`. There is no saga status `compensated`.

See [Compensation Strategy](https://mkdocs.python-cqrs.dev/latest/saga/compensation/index.md).

`execute` raises the step error after compensation, so Act waits for it with `pytest.raises`.

```python
class ChargeCard(cqrs.SagaStepHandler[OrderContext, None]):
    async def act(self, context: OrderContext):
        raise CardDeclined("card declined")

    async def compensate(self, context: OrderContext) -> None:
        return None

class OrderSaga(cqrs.Saga[OrderContext]):
    steps = [ReserveStock, ChargeCard]

async def test_failed_step_compensates_finished_steps() -> None:
    container = di.Container()
    async with test_harness(container, sagas_mapper=sagas_mapper) as harness:
        with pytest.raises(CardDeclined):
            async for _ in harness.saga_mediator.execute(OrderContext(order_id="1")):
                pass

        assert harness.invocations.of(ReserveStock)[-1].method == "compensate"
        saga = harness.sagas.one(OrderSaga)
        assert saga.status is SagaStatus.FAILED
        assert saga.step_status("ReserveStock") is SagaStepStatus.COMPENSATED
```

Library example: [`examples/testing/test_saga.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_saga.py).
