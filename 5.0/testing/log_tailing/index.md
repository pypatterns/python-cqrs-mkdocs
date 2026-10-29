# Transaction log tailing

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

This is not run through `test_harness`. Transaction log tailing is a process that reads the database log, not `mediator.send`. The harness journals stay empty.

python-cqrs publishes by polling outbox storage. That path is [Outbox](https://mkdocs.python-cqrs.dev/latest/testing/outbox/index.md) and [Transactional outbox](https://mkdocs.python-cqrs.dev/latest/outbox/index.md).

The same outbox table can be tailed outside this package with [Debezium and Kafka Connect](https://debezium.io/documentation/reference/stable/architecture.html). New outbox rows are then produced to the broker topic.
