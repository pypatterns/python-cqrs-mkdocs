---
title: Transaction log tailing
description: A process that reads the database log. It is not mediator.send and is not run through the harness.
---

# Transaction log tailing

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

This is not run through `test_harness`. Transaction log tailing is a process that reads the database log, not `mediator.send`. The harness journals stay empty.

python-cqrs publishes by polling outbox storage. That path is [Outbox](outbox.md) and [Transactional outbox](../outbox/index.md).

The same outbox table can be tailed outside this package with [Debezium and Kafka Connect](https://debezium.io/documentation/reference/stable/architecture.html). New outbox rows are then produced to the broker topic.
