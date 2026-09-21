# Reference

- **Back to Stream Handling Overview**

  Return to the Stream Handling overview page with all topics.

  [Back to Overview](https://vadikko2.github.io/python-cqrs-mkdocs/stream_handling/index.md)

______________________________________________________________________

### Incremental Processing

Streaming handlers process items one at a time, yielding results as they become available. This allows clients to receive progress updates in real-time.

### Event Emission

After each yield, events are collected and can be emitted. Events are processed after each yield, allowing for parallel processing of side effects.

### Parallel Event Processing

Events can be processed concurrently with configurable concurrency limits. This improves performance when multiple event handlers need to process events independently.

### SSE Integration

Streaming handlers work seamlessly with Server-Sent Events (SSE) in FastAPI, enabling real-time progress updates in web applications.

Streaming handlers are ideal for:

- **Batch processing** — Processing large batches of items with progress updates
- **File uploads** — Processing uploaded files one by one
- **Data import** — Importing data with real-time progress
- **Long-running operations** — Operations that take time and benefit from progress updates
- **Real-time updates** — Applications that need to show progress to users
- **Clear events after processing** — Implement `clear_events()` to prevent event accumulation
- **Use appropriate concurrency limits** — Set `max_concurrent_event_handlers` based on your resource constraints
- **Handle errors gracefully** — Wrap streaming logic in try-except blocks
- **Yield meaningful results** — Include progress information in response objects
- **Use SSE for web applications** — Stream results via SSE for better user experience

| Feature          | Regular Handler   | Streaming Handler             |
| ---------------- | ----------------- | ----------------------------- |
| Response         | Single response   | Multiple responses (yielded)  |
| Processing       | All at once       | Incremental                   |
| Progress Updates | Not available     | Real-time                     |
| Event Processing | After completion  | After each yield              |
| Use Case         | Simple operations | Batch/long-running operations |

### API Contract and Typing

**StreamingRequestHandler**

The base class declares `handle` as a **sync** method returning an iterator: `def handle(self, request: ReqT) -> AsyncIterator[ResT]`. Subclasses implement it as an **async generator** (`async def handle(...): ... yield ...`). This keeps types compatible with Pyright and mypy — **no type ignores** are needed on your handler's `handle` method.

**Stream and consumption**

- `mediator.stream(request)` is called **without** `await`.
- It returns an `AsyncIterator`; consume it with `async for`:

```python
# Correct: no await, iterate with async for
async for result in mediator.stream(command):
    print(result)
```
