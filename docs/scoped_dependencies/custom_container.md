---
title: Custom Scoped Container
description: Implement SupportsScope.open_scope for your own DI library.
---

# Custom Container

`Container.resolve` is enough for unscoped DI. To enable scopes, add `open_scope`:

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
6. **Do not wrap `ScopeAwareContainer` yourself** — mediators, `saga.transaction`, and `recover_saga` wrap a plain container internally. Resolving the **root** container directly inside `enter_scope` still one-shots; that is the intended contract.

See `examples/di/scoped_dependencies_custom_container.py` for a ~80-line template.
