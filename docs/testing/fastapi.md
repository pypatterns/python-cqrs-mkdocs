---
title: FastAPI
description: TestClient and dependency_overrides. Assert requests and outbox. The harness does not import FastAPI.
---

# FastAPI

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

The harness does not import FastAPI. `TestClient` calls the route, and `dependency_overrides` installs the mediator. Assert `requests` and `outbox`. `published` stays empty while the row is still pending.

See [FastAPI](../fastapi.md).

Import the module, not `TestClient` itself: pytest tries to collect any `Test*` name in a test module.

```python
from fastapi import testclient

async def test_route_sends_the_command_and_stores_the_row() -> None:
    mediator = bootstrap.bootstrap(
        di_container=di.Container(),
        commands_mapper=commands_mapper,
    )
    app.dependency_overrides[mediator_factory] = lambda: mediator
    client = testclient.TestClient(app)
    async with test_harness.around(mediator, outbox=outbox) as harness:
        response = client.post("/orders", json={"sku": "book"})

        assert response.status_code == 201
        assert harness.requests.contains(CreateOrder)
        assert harness.outbox.pending_count == 1
```

Library example: [`examples/testing/test_fastapi_app.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_fastapi_app.py).
