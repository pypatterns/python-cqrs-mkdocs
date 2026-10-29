# SQLModel outbox

The harness does not import SQLModel. Mark the test `sqlmodel`. Read `outbox` on `SqlModelOutboxedEventRepository`. `published` stays empty until `produce_available`.

See [ORM](https://mkdocs.python-cqrs.dev/latest/orm/index.md).

```python
outbox = cqrs.outbox.sqlmodel.SqlModelOutboxedEventRepository(session, event_map=event_map)
async with test_harness.around(mediator, outbox=outbox) as harness:
    await mediator.send(CreateOrder(sku="book"))
    assert harness.outbox.pending_count == 1
```

Library example: [`examples/testing/sqlmodel_outbox.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/sqlmodel_outbox.py).
