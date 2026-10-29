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

The count inside the loop is kept in a variable during Act and checked in Assert, so the test has one place for assertions.

```python
class OrderSaga(cqrs.Saga[OrderContext]):
    steps = [ReserveStock, ChargeCard]

def sagas_mapper(mapper: cqrs.SagaMap) -> None:
    mapper.bind(OrderContext, OrderSaga)

async def test_saga_step_acts_and_the_saga_completes() -> None:
    container = di.Container()
    async with test_harness(container, sagas_mapper=sagas_mapper) as harness:
        running_after_reserve = None
        async for step in harness.saga_mediator.execute(OrderContext(order_id="1")):
            if step.step_type is ReserveStock:
                running_after_reserve = harness.sagas.running_count

        assert running_after_reserve == 1
        assert harness.invocations.of(ReserveStock)[0].method == "act"
        assert harness.sagas.running_count == 0
        assert harness.sagas.completed_count == 1
        assert harness.sagas.one(OrderSaga).completed_steps == ["ReserveStock", "ChargeCard"]
```

Library example: [`examples/testing/test_saga.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_saga.py).
