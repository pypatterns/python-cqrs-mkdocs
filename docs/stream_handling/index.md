---
title: Stream Handling in python-cqrs
description: Incremental request streaming and Server-Sent Events (SSE) with python-cqrs and FastAPI integration.
---

# Stream Handling

Stream handling allows you to process requests incrementally and yield results as they become available. This is particularly useful for processing large batches of items, file uploads, or any operation that benefits from real-time progress updates.

Coding agents build this with [cqrs-streaming-requests](https://github.com/pypatterns/python-cqrs/blob/master/skills/cqrs-streaming-requests/SKILL.md) after [cqrs-core-setup](https://github.com/pypatterns/python-cqrs/blob/master/skills/cqrs-core-setup/SKILL.md) has chosen a stream. The catalog is [Agent skills](../skills.md).

## Overview

<div class="grid cards" markdown>

-   :material-cog: **Configuration**

    Bootstrap setup and mediator usage for streaming requests.

    [:octicons-arrow-right-24: Read More](configuration.md)

-   :material-web: **FastAPI Integration**

    SSE integration examples for real-time progress updates.

    [:octicons-arrow-right-24: Read More](fastapi_integration.md)

-   :material-book-open-page-variant: **Reference**

    Key features, use cases, and best practices for stream handling.

    [:octicons-arrow-right-24: Read More](reference.md)

-   :material-backup-restore: **Fallback**

    Fallback streaming handler when primary stream fails.

    [:octicons-arrow-right-24: Read More](fallback.md)

</div>

`StreamingRequestHandler` works with `StreamingRequestMediator` to process requests incrementally. The handler yields results as they become available, and events are processed after each yield. This enables:

- **Real-time progress updates** — Clients receive results as they're processed
- **Better user experience** — No need to wait for entire batch to complete
- **Parallel event processing** — Events can be processed concurrently while streaming
- **SSE integration** — Perfect for Server-Sent Events in web applications

!!! note "Prerequisites"
    Understanding of [Request Handlers](../request_handler/index.md) and [Bootstrap](../bootstrap/index.md) is recommended.

!!! tip "Use Cases"
    Streaming is ideal for large batch operations, file processing, or any scenario where you want to provide real-time feedback. See [FastAPI Integration](fastapi_integration.md) for SSE examples.

## Basic Example

Here's a simple example of a streaming handler:

```python
from datetime import datetime
import cqrs
from cqrs.handlers.request import StreamingRequestHandler
from cqrs.models.event import Event

class FileProcessedResult(cqrs.Response):
    file_id: str
    status: str
    processed_at: datetime

class ProcessFilesCommand(cqrs.Request[FileProcessedResult]):
    file_ids: list[str]

class ProcessFilesCommandHandler(StreamingRequestHandler[ProcessFilesCommand]):
    def __init__(self):
        self._events: list[Event] = []

    @property
    def events(self) -> list[Event]:
        return self._events.copy()

    def clear_events(self) -> None:
        self._events.clear()

    async def handle(self, request: ProcessFilesCommand):
        for file_id in request.file_ids:
            result = FileProcessedResult(
                file_id=file_id,
                status="completed",
                processed_at=datetime.now(),
            )
            self._events.append(FileProcessedEvent(file_id=file_id))
            yield result
```

!!! tip "Typing"
    Declare the command as `Request[FileProcessedResult]` and the handler as `StreamingRequestHandler[ProcessFilesCommand]`. Do not annotate the element type on `handle`; `async for` yields `FileProcessedResult`. Call `mediator.stream(request)` **without** `await`.

**Legacy (still supported).** `StreamingRequestHandler[Command, Result]` with an element annotation on `handle` still works. Copy the one-argument form above.

```python
class ProcessFilesCommandHandler(StreamingRequestHandler[ProcessFilesCommand, FileProcessedResult]):
    async def handle(self, request: ProcessFilesCommand) -> typing.AsyncIterator[FileProcessedResult]:
        ...
```

Runnable example: [`examples/streaming/typed_streaming_handler.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/streaming/typed_streaming_handler.py).
