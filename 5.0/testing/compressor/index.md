# Compressor

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

This is not run through `test_harness`. `ZlibCompressor` is checked by the existing serializer tests. The harness sees `payload_bytes` as bytes that are already finished, so the compressor writes no journal of its own. `invocations` stays empty.

See [Outbox implementation](https://mkdocs.python-cqrs.dev/latest/outbox/implementation/index.md).

```python
def test_zlib_round_trip_returns_the_payload() -> None:
    compressor = cqrs.ZlibCompressor()
    payload = b'{"order_id": "1"}'

    restored = compressor.decompress(compressor.compress(payload))

    assert restored == payload
```

Library example: [`examples/testing/test_outside_harness.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_outside_harness.py).
