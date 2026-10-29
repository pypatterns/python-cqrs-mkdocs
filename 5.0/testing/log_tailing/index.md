# Transaction log tailing

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

This is not run through `test_harness`. Transaction log tailing is a process that reads the database log, not `mediator.send`. The harness journals stay empty.

The polling path that the harness does run is [Outbox](https://mkdocs.python-cqrs.dev/latest/testing/outbox/index.md).

See [Transactional outbox](https://mkdocs.python-cqrs.dev/latest/outbox/index.md). The README section is [Transaction log tailing](https://github.com/vadikko2/python-cqrs/blob/master/README.md#transaction-log-tailing).
