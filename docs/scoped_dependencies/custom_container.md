---
title: Custom Scoped Container
description: Implement SupportsScope.open_scope when python-cqrs has no adapter for your DI library.
---

# Custom Container

<div class="grid cards" markdown>

-   :material-home: **Back to Scoped Dependencies Overview**

    Return to the Scoped Dependencies overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

-   :material-cog: **Advanced**

    `enter_scope`, `bind_scope`, and FastAPI middleware.

    [:octicons-arrow-right-24: Read More](advanced.md)

</div>

---

You need this page only if you are **not** using `di` or dishka (or you must wrap a library python-cqrs does not ship). For a SQLAlchemy session that lasts for `send()`, copy the [Tutorial](tutorial.md) instead.

`Container.resolve` is enough for unscoped DI. To enable CQRS scopes, add `open_scope`:

```python
@typing.runtime_checkable
class SupportsScope(typing.Protocol[C]):
    def open_scope(
        self,
        context: typing.Mapping[type, typing.Any] | None = None,
    ) -> typing.AsyncContextManager[Container[C]]: ...
```

## Checklist

1. **`open_scope` yields a new object**, never `self` — otherwise concurrent `send()` share one UoW.
2. **Finalize on exit** — commit/rollback/close generator providers in the context manager’s `__aexit__`.
3. **Propagate exceptions** — do not swallow handler errors so rollback can run. Under `HANDLER` fallback the framework re-raises through this exit so a generator UoW (`yield session; commit()`) rolls back the failed primary.
4. **Optional** — skipping `open_scope` is valid; the framework no-ops and behaviour stays as today.
5. **Structural typing** — `SupportsScope` is `runtime_checkable`; inheritance is not required.
6. **Do not wrap the container yourself** — mediators, `saga.transaction`, and `recover_saga` wrap a plain container internally. Resolving the **root** container directly inside `enter_scope` still one-shots; that is the intended contract.

See [`examples/di/scoped_dependencies_custom_container.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/di/scoped_dependencies_custom_container.py) for a ~80-line template.
