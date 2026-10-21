# Stream Handling

Stream handling allows you to process requests incrementally and yield results as they become available. This is particularly useful for processing large batches of items, file uploads, or any operation that benefits from real-time progress updates.

## Overview

- **Configuration**

  Bootstrap setup and mediator usage for streaming requests.

  [Read More](https://mkdocs.python-cqrs.dev/latest/stream_handling/configuration/index.md)

- **FastAPI Integration**

  SSE integration examples for real-time progress updates.

  [Read More](https://mkdocs.python-cqrs.dev/latest/stream_handling/fastapi_integration/index.md)

- **Reference**

  Key features, use cases, and best practices for stream handling.

  [Read More](https://mkdocs.python-cqrs.dev/latest/stream_handling/reference/index.md)

- **Fallback**

  Fallback streaming handler when primary stream fails.

  [Read More](https://mkdocs.python-cqrs.dev/latest/stream_handling/fallback/index.md)

`StreamingRequestHandler` works with `StreamingRequestMediator` to process requests incrementally. The handler yields results as they become available, and events are processed after each yield. This enables:

- **Real-time progress updates** — Clients receive results as they're processed
- **Better user experience** — No need to wait for entire batch to complete
- **Parallel event processing** — Events can be processed concurrently while streaming
- **SSE integration** — Perfect for Server-Sent Events in web applications

Prerequisites

Understanding of [Request Handlers](https://mkdocs.python-cqrs.dev/latest/request_handler/index.md) and [Bootstrap](https://mkdocs.python-cqrs.dev/latest/bootstrap/index.md) is recommended.

Use Cases

Streaming is ideal for large batch operations, file processing, or any scenario where you want to provide real-time feedback. See [FastAPI Integration](https://mkdocs.python-cqrs.dev/latest/stream_handling/fastapi_integration/index.md) for SSE examples.

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

Typing

Declare the command as `Request[FileProcessedResult]` and the handler as `StreamingRequestHandler[ProcessFilesCommand]`. Do not annotate the element type on `handle`; `async for` yields `FileProcessedResult`. Call `mediator.stream(request)` **without** `await`.

**Legacy (still supported).** `StreamingRequestHandler[Command, Result]` with an element annotation on `handle` still works. Copy the one-argument form above.

```python
class ProcessFilesCommandHandler(StreamingRequestHandler[ProcessFilesCommand, FileProcessedResult]):
    async def handle(self, request: ProcessFilesCommand) -> typing.AsyncIterator[FileProcessedResult]:
        ...
```

Runnable example: [`examples/streaming/typed_streaming_handler.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/streaming/typed_streaming_handler.py).
