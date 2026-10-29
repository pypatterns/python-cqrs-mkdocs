# FastAPI

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

The harness does not import FastAPI. `TestClient` calls the route, and `dependency_overrides` installs the mediator. Assert `requests` and `outbox`. `published` stays empty while the row is still pending.

See [FastAPI](https://mkdocs.python-cqrs.dev/latest/fastapi/index.md).

```python
from fastapi.testclient import TestClient

app.dependency_overrides[mediator_factory] = lambda: mediator
async with test_harness.around(mediator, outbox=outbox) as harness:
    response = TestClient(app).post("/orders", json={"sku": "book"})
    assert response.status_code == 201
    assert harness.requests.contains(CreateOrder)
    assert harness.outbox.pending_count == 1
```

Library example: [`examples/testing/fastapi_app.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/fastapi_app.py).
