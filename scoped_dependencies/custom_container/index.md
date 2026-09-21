# Custom Container

- **Back to Scoped Dependencies Overview**

  Return to the Scoped Dependencies overview page with all topics.

  [Back to Overview](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/index.md)

- **Advanced**

  `enter_scope`, `bind_scope`, and FastAPI middleware.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/advanced/index.md)

______________________________________________________________________

You need this page only if you are **not** using `di` or dishka (or you must wrap a library python-cqrs does not ship). For a SQLAlchemy session that lasts for `send()`, copy the [Tutorial](https://vadikko2.github.io/python-cqrs-mkdocs/scoped_dependencies/tutorial/index.md) instead.

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
1. **Finalize on exit** — commit/rollback/close generator providers in the context manager’s `__aexit__`.
1. **Propagate exceptions** — do not swallow handler errors so rollback can run. Under `HANDLER` fallback the framework re-raises through this exit so a generator UoW (`yield session; commit()`) rolls back the failed primary.
1. **Optional** — skipping `open_scope` is valid; the framework no-ops and behaviour stays as today.
1. **Structural typing** — `SupportsScope` is `runtime_checkable`; inheritance is not required.
1. **Do not wrap the container yourself** — mediators, `saga.transaction`, and `recover_saga` wrap a plain container internally. Resolving the **root** container directly inside `enter_scope` still one-shots; that is the intended contract.

See [`examples/di/scoped_dependencies_custom_container.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/di/scoped_dependencies_custom_container.py) for a ~80-line template.
