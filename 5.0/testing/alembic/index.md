# Alembic

This is not run through `test_harness`. Rebind is a migration, not a handler run, so `requests` stays empty. The fence below is the short form.

See [Database support](https://mkdocs.python-cqrs.dev/latest/outbox/databases/index.md) for the full call.

```python
cqrs.rebind_outbox_model(Base)
Base.metadata.create_all(engine)
```
