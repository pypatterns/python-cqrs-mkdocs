---
title: Protobuf messages
description: Published message content_type and payload_bytes. The harness does not import protobuf.
---

# Protobuf messages

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

`published` carries `content_type` `application/x-protobuf` and `payload_bytes`. The harness does not import protobuf. Mark the test `protobuf`. `handled` stays empty.

See [Protobuf](../protobuf.md).

```python
pytestmark = pytest.mark.protobuf

async def test_notification_is_published_as_protobuf() -> None:
    container = di.Container()
    serializer = cqrs.ProtobufEventSerializer({OrderCreatedNotice: order_pb2.OrderCreated})
    async with test_harness(
        container,
        commands_mapper=commands_mapper,
        serializer=serializer,
    ) as harness:
        await harness.mediator.send(CreateOrder(sku="book"))

        message = harness.published.one(OrderCreatedNotice)
        assert message.content_type == "application/x-protobuf"
        assert message.payload_bytes
```

Library example: [`examples/testing/test_protobuf_notification.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_protobuf_notification.py).
