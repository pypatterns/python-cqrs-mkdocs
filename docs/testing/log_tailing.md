---
title: Transaction log tailing
description: A process that reads the database log. It is not mediator.send and is not run through the harness.
---

# Transaction log tailing

This is not run through `test_harness`. Transaction log tailing is a process that reads the database log, not `mediator.send`. The harness journals stay empty.

The polling path that the harness does run is [Outbox](outbox.md).

See [Transactional outbox](../outbox/index.md). The README section is [Transaction log tailing](https://github.com/vadikko2/python-cqrs/blob/master/README.md#transaction-log-tailing).
