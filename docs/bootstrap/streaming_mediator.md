# Streaming Mediator

<div class="grid cards" markdown>

-   :material-home: **Back to Bootstrap Overview**

    Return to the Bootstrap overview page with all configuration options.

    [:octicons-arrow-left-24: Back to Overview](index.md)

-   :material-play-circle: **Stream Handling**

    Incremental processing, SSE, and streaming configuration.

    [:octicons-arrow-right-24: Read More](../stream_handling/index.md)

</div>

---

## Overview

The `StreamingRequestMediator` processes requests incrementally, yielding results as they become available. Perfect for batch processing, file uploads, and real-time progress updates.

### Basic Configuration

```python
from cqrs.requests import bootstrap

def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(ProcessFilesCommand, ProcessFilesCommandHandler)

def events_mapper(mapper: cqrs.EventMap) -> None:
    mapper.bind(FileProcessedEvent, FileProcessedEventHandler)

mediator = bootstrap.bootstrap_streaming(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    domain_events_mapper=events_mapper,
)
```

`StreamingRequestMediator(..., scope_strategy=ScopeStrategy.SEND)` and `bootstrap_streaming(..., scope_strategy=ScopeStrategy.SEND)` work out of the box: `concurrent_event_handle_enable` defaults to `None` (`False` under SEND). Do not pass `concurrent_event_handle_enable=True` with SEND. Consume the stream fully or close it with `aclose()` / `async with aclosing(...)` — an abandoned SEND stream holds the UoW until GC.

```python
from cqrs import ScopeStrategy

mediator = bootstrap.bootstrap_streaming(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    domain_events_mapper=events_mapper,
    scope_strategy=ScopeStrategy.SEND,  # sequential events; no concurrent=False needed
)
```

### With Parallel Event Processing

Without SEND, `concurrent_event_handle_enable=None` becomes `True` (streaming default). Under SEND it becomes `False` (sequential BFS). Parallel events need `HANDLER` or `NONE`.

```python
from cqrs import ScopeStrategy

# Streaming mediator: None → True unless SEND
mediator = bootstrap.bootstrap_streaming(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    domain_events_mapper=events_mapper,
    scope_strategy=ScopeStrategy.HANDLER,  # or omit for NONE
    max_concurrent_event_handlers=10,  # Default: 10
    concurrent_event_handle_enable=True,
)
```

### With Message Broker

```python
from cqrs.message_brokers import kafka
from cqrs.adapters.kafka import KafkaProducerAdapter

kafka_producer = KafkaProducerAdapter(
    bootstrap_servers=["localhost:9092"],
)

mediator = bootstrap.bootstrap_streaming(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    domain_events_mapper=events_mapper,
    message_broker=kafka.KafkaMessageBroker(producer=kafka_producer),
)
```

### Complete Example

```python
import typing
import asyncio
import di
import cqrs
from cqrs.requests import bootstrap
from cqrs.requests.request_handler import StreamingRequestHandler
from cqrs.message_brokers import devnull

class ProcessFilesCommand(cqrs.Request):
    file_ids: list[str]

class FileProcessedResult(cqrs.Response):
    file_id: str
    status: str

class FileProcessedEvent(cqrs.DomainEvent):
    file_id: str
    status: str

class ProcessFilesCommandHandler(
    StreamingRequestHandler[ProcessFilesCommand, FileProcessedResult]
):
    def __init__(self):
        self._events = []

    @property
    def events(self) -> list[cqrs.Event]:
        return self._events.copy()

    def clear_events(self) -> None:
        self._events.clear()

    async def handle(
        self, request: ProcessFilesCommand
    ) -> typing.AsyncIterator[FileProcessedResult]:
        for file_id in request.file_ids:
            # Simulate processing
            await asyncio.sleep(0.1)
            result = FileProcessedResult(file_id=file_id, status="completed")
            self._events.append(
                FileProcessedEvent(file_id=file_id, status="completed")
            )
            yield result

class FileProcessedEventHandler(cqrs.EventHandler[FileProcessedEvent]):
    async def handle(self, event: FileProcessedEvent) -> None:
        print(f"File {event.file_id} processed")

def commands_mapper(mapper: cqrs.RequestMap) -> None:
    mapper.bind(ProcessFilesCommand, ProcessFilesCommandHandler)

def events_mapper(mapper: cqrs.EventMap) -> None:
    mapper.bind(FileProcessedEvent, FileProcessedEventHandler)

mediator = bootstrap.bootstrap_streaming(
    di_container=di.Container(),
    commands_mapper=commands_mapper,
    domain_events_mapper=events_mapper,
    message_broker=devnull.DevnullMessageBroker(),
    max_concurrent_event_handlers=5,
    concurrent_event_handle_enable=True,
)

# Stream results — exhaust or aclose(); abandoned SEND holds UoW until GC
from contextlib import aclosing

async with aclosing(
    mediator.stream(ProcessFilesCommand(file_ids=["1", "2", "3"]))
) as stream:
    async for result in stream:
        if result:
            print(f"Processed: {result.file_id} - {result.status}")
```
