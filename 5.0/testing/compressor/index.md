# Compressor

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

This is not run through `test_harness`. `ZlibCompressor` is checked by the existing serializer tests. The harness sees `payload_bytes` as bytes that are already finished, so the compressor writes no journal of its own. `invocations` stays empty.

See [Outbox implementation](https://mkdocs.python-cqrs.dev/latest/outbox/implementation/index.md).

```python
compressed = cqrs.ZlibCompressor().compress(message.payload_bytes)
assert cqrs.ZlibCompressor().decompress(compressed) == message.payload_bytes
```
