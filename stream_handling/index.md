# Stream Handling

Stream handling allows you to process requests incrementally and yield results as they become available. This is particularly useful for processing large batches of items, file uploads, or any operation that benefits from real-time progress updates.

## Overview

- **Configuration**

  Bootstrap setup and mediator usage for streaming requests.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/stream_handling/configuration/index.md)

- **FastAPI Integration**

  SSE integration examples for real-time progress updates.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/stream_handling/fastapi_integration/index.md)

- **Reference**

  Key features, use cases, and best practices for stream handling.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/stream_handling/reference/index.md)

- **Fallback**

  Fallback streaming handler when primary stream fails.

  [Read More](https://vadikko2.github.io/python-cqrs-mkdocs/stream_handling/fallback/index.md)

`StreamingRequestHandler` works with `StreamingRequestMediator` to process requests incrementally. The handler yields results as they become available, and events are processed after each yield. This enables:

- **Real-time progress updates** — Clients receive results as they're processed
- **Better user experience** — No need to wait for entire batch to complete
- **Parallel event processing** — Events can be processed concurrently while streaming
- **SSE integration** — Perfect for Server-Sent Events in web applications

Prerequisites

Understanding of [Request Handlers](https://vadikko2.github.io/python-cqrs-mkdocs/request_handler/index.md) and [Bootstrap](https://vadikko2.github.io/python-cqrs-mkdocs/bootstrap/index.md) is recommended.

Use Cases

Streaming is ideal for large batch operations, file processing, or any scenario where you want to provide real-time feedback. See [FastAPI Integration](https://vadikko2.github.io/python-cqrs-mkdocs/stream_handling/fastapi_integration/index.md) for SSE examples.

## Basic Example

Here's a simple example of a streaming handler:

```python
import typing
from datetime import datetime
import cqrs
from cqrs.requests.request_handler import StreamingRequestHandler
from cqrs.events.event import Event

class ProcessFilesCommand(cqrs.Request):
    file_ids: list[str]

class FileProcessedResult(cqrs.Response):
    file_id: str
    status: str
    processed_at: datetime

class ProcessFilesCommandHandler(
    StreamingRequestHandler[ProcessFilesCommand, FileProcessedResult]
):
    def __init__(self):
        self._events: list[Event] = []

    @property
    def events(self) -> list[Event]:
        return self._events.copy()

    def clear_events(self) -> None:
        self._events.clear()

    async def handle(
        self, request: ProcessFilesCommand
    ) -> typing.AsyncIterator[FileProcessedResult]:
        for file_id in request.file_ids:
            # Process file
            result = FileProcessedResult(
                file_id=file_id,
                status="completed",
                processed_at=datetime.now()
            )

            # Emit events
            self._events.append(
                FileProcessedEvent(file_id=file_id, ...)
            )

            # Yield result - events will be processed after this yield
            yield result
```

Typing

The base `StreamingRequestHandler` declares `def handle(...) -> AsyncIterator[ResT]`. Your subclass implements it as an async generator (`async def handle(...): yield ...`). This is type-safe; no `# type: ignore` is needed. Call `mediator.stream(request)` **without** `await` and consume the result with `async for`.
