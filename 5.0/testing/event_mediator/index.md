# Event Mediator

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

`invocations` records the handler, and the method is `handle`. `EventMediator` goes through `EventDispatcher`, not `EventEmitter`, so this is not the `handled` journal.

See [Event Mediator](https://mkdocs.python-cqrs.dev/latest/bootstrap/event_mediator/index.md).

```python
def events_mapper(mapper: cqrs.EventMap) -> None:
    mapper.bind(OrderCreated, AuditHandler)

async def test_event_mediator_enters_handle() -> None:
    container = di.Container()
    async with test_harness(container, events_mapper=events_mapper) as harness:
        await harness.event_mediator.send(OrderCreated(order_id="1"))

        harness.invocations.assert_entered(AuditHandler)
        assert harness.invocations.of(AuditHandler)[0].method == "handle"
```

Library example: [`examples/testing/test_event_mediator.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_event_mediator.py).
