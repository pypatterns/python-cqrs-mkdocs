---
title: Protobuf messages
description: Published message content_type and payload_bytes. The harness does not import protobuf.
---

# Protobuf messages

`published` carries `content_type` `application/x-protobuf` and `payload_bytes`. The harness does not import protobuf. Mark the test `protobuf`. `handled` stays empty.

See [Protobuf](../protobuf.md).

```python
async with test_harness(
    container,
    commands_mapper=commands_mapper,
    serializer=cqrs.ProtobufEventSerializer({OrderCreatedNotice: order_pb2.OrderCreated}),
) as harness:
    await harness.mediator.send(CreateOrder(sku="book"))
    message = harness.published.one(OrderCreatedNotice)
    assert message.content_type == "application/x-protobuf"
    assert message.payload_bytes
```

Library example: [`examples/testing/protobuf_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/protobuf_notification.py).
