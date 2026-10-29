# Parallel Handlers

Both handler classes are on `invocations`. Do not assert their order.

See [Parallel Event Processing](https://mkdocs.python-cqrs.dev/latest/event_handler/parallel_processing/index.md).

```python
async with test_harness(
    container,
    commands_mapper=commands_mapper,
    domain_events_mapper=domain_events_mapper,
    concurrent_event_handle_enable=True,
    scope_strategy=cqrs.ScopeStrategy.HANDLER,
) as harness:
    await harness.mediator.send(CreateOrder(sku="book"))
    harness.invocations.assert_entered(AuditHandler)
    harness.invocations.assert_entered(SearchHandler)
```

Library example: [`examples/testing/parallel_handlers.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/parallel_handlers.py).
