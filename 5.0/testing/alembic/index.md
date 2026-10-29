# Alembic

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

This is not run through `test_harness`. Rebind is a migration, not a handler run, so `requests` stays empty.

`rebind_outbox_model(model, new_base, table_name)` changes `OutboxModel` for the whole process. The fixture puts the original base and table name back after the test.

See [Database support](https://mkdocs.python-cqrs.dev/latest/outbox/databases/index.md) for the full call.

```python
import pytest
import sqlalchemy
from sqlalchemy import orm

import cqrs

@pytest.fixture
def outbox_model():
    from cqrs.outbox.sqlalchemy import OutboxModel

    original_base = OutboxModel.__bases__[0]
    original_name = OutboxModel.__table__.name
    yield OutboxModel
    cqrs.rebind_outbox_model(OutboxModel, original_base, original_name)

@pytest.mark.sqlalchemy
def test_rebind_puts_the_outbox_table_on_the_application_metadata(outbox_model) -> None:
    Base = orm.registry().generate_base()
    engine = sqlalchemy.create_engine("sqlite://")

    cqrs.rebind_outbox_model(outbox_model, Base, "app_outbox")
    Base.metadata.create_all(engine)

    assert "app_outbox" in sqlalchemy.inspect(engine).get_table_names()
```

Library example: [`examples/testing/test_outside_harness.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_outside_harness.py).
