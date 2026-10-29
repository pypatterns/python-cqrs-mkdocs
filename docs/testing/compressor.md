---
title: Compressor
description: ZlibCompressor is checked by the serializer tests. The harness sees payload_bytes as finished bytes.
---

# Compressor

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

This is not run through `test_harness`. `ZlibCompressor` is checked by the existing serializer tests. The harness sees `payload_bytes` as bytes that are already finished, so the compressor writes no journal of its own. `invocations` stays empty.

See [Outbox implementation](../outbox/implementation.md).

```python
compressed = cqrs.ZlibCompressor().compress(message.payload_bytes)
assert cqrs.ZlibCompressor().decompress(compressed) == message.payload_bytes
```
