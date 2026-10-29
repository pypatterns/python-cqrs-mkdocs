---
title: Chain of Responsibility
description: Assert the entered step on the invocations journal.
---

# Chain of Responsibility

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`invocations` shows `CardHandler` entered and `CashHandler` not entered. There is no separate chain bus. `handled` contains an event only from the step that returned.

See [Chain of Responsibility](../chain_of_responsibility/index.md).

```python
class CardHandler(cqrs.handlers.CORRequestHandler[PayOrder]):
    async def handle(self, request: PayOrder):
        if request.method != "card":
            return await self.next(request)
        return Paid(method="card")

def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(PayOrder, [CardHandler, CashHandler])

result = await harness.mediator.send(PayOrder(method="card"))
assert result.method == "card"
harness.invocations.assert_entered(CardHandler)
harness.invocations.assert_not_entered(CashHandler)
```

Library example: [`examples/testing/chain.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/chain.py).
