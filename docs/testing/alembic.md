---
title: Alembic
description: rebind is a migration, not a handler run. The fence is the short form.
---

# Alembic

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

This is not run through `test_harness`. Rebind is a migration, not a handler run, so `requests` stays empty. The fence below is the short form.

See [Database support](../outbox/databases.md) for the full call.

```python
cqrs.rebind_outbox_model(Base)
Base.metadata.create_all(engine)
```
