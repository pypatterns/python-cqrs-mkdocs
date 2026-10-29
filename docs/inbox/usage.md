---
title: Using the transactional inbox
description: Batch add, message names, SKIP LOCKED reads, and separate sessions for accept and process.
---

# Usage

`add` always takes a batch and returns `list[bool]` of the same length. One record is a batch of one element. There is no second method for a single message.

[Testing an inbox handler error](../testing/inbox_failure.md) leaves the row `not_processed` and increments `flush_counter`.

```python
stored = await inbox.add(
    [
        ("msg-1", ProcessDeposit(account_id="acc-1", amount="10.00")),
        ("msg-2", ProcessDeposit(account_id="acc-2", amount="5.00")),
    ],
)
```

`True` means the row was inserted. `False` means `(message_id, message_name)` is already in the table, or already earlier in this batch. An empty batch returns `[]`. One duplicate does not cancel the other elements and does not abort the outer transaction: each element is inserted in its own savepoint. `add` does not commit. The caller opens a session, calls `add`, and commits.

```python
async with session_factory() as session:
    inbox = cqrs.SqlAlchemyInboxRepository(session, message_map=message_map)
    stored = await inbox.add(
        [("msg-1", ProcessDeposit(account_id="acc-1", amount="10.00"))],
    )
    await session.commit()
```

`open_scope` and `bind_scope` are for the extra case: the same presentation transaction must also write another row. That case is [`presentation_scope.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/inbox/presentation_scope.py).

## Names

`InboxMessageMap` maps a name to a request or event type. JSON is the default codec. A second `register` of the same name raises `KeyError`. Prefer `InboxMessageMap()` when tests must not share the process-global map.

Requests and domain events are stored under the class name. Notification events are stored under `event_name`, the same string the outbox uses.

```python
message_map = cqrs.InboxMessageMap()
message_map.register("ProcessDeposit", ProcessDeposit)
message_map.register("order_created", OrderCreated)

repository = cqrs.SqlAlchemyInboxRepository(session, message_map=message_map)
```

`SqlAlchemyInboxRepository` needs `python-cqrs[sqlalchemy]`. `SqlModelInboxRepository` needs `python-cqrs[sqlmodel]`. Both names are lazy on `cqrs`. Call `cqrs.rebind_inbox_model` when the inbox table must live on the application's metadata.

The table is `id`, `message_id`, `message_name`, `status`, `flush_counter`, `created_at`, `payload`, with a unique `(message_id, message_name)`. Status values match the outbox lifecycle: `new`, `processed`, `not_processed`.

## Reading

`get_many(batch_size=100)` returns at most `batch_size` rows whose status is `new` or `not_processed` and whose `flush_counter` is below five, ordered by `id`. On PostgreSQL and MySQL the SQL implementation takes those rows with `FOR UPDATE SKIP LOCKED`, so a second worker does not run the same row while the first transaction is open. SQLite does not take that lock.

Construct `InboxProcessor` with the repository for that session, the message map, and the mediators. `batch_generator` yields `get_many` lists from that repository until the caller stops it. The caller commits after a batch. The processor does not.

```python
processor = cqrs.InboxProcessor(
    inbox,
    message_map,
    request_mediator=request_mediator,
)
async for rows in processor.batch_generator():
    for row in rows:
        await processor.process(row)
    await session.commit()
```

`process(row)` deserializes the row through the message map. A `Request` goes to `RequestMediator.send`. An event goes to `EventMediator.send`. Success marks that row `processed` inside a savepoint on the injected repository, so the business write and the status commit together. An exception rolls back only that savepoint. `not_processed` and the incremented `flush_counter` are written on the outer transaction and commit with the rest of the batch. On the fifth failure the row leaves `get_many`.

The handler must not call `session.commit()`. The worker opens one session for the batch, builds the repository and the mediator from that session, constructs the processor with that repository, and commits after `process` returns. That commit stores the business rows and the status together.

## Two sessions

Presentation opens a session, calls `add`, and commits. Acknowledge the broker, or return HTTP 202, after that commit. The processor later opens a different session and reads rows that are already committed.

`False` in the accept batch is still ack or 202. The row is already stored. An exception before the commit rolls the whole batch back, and the transport delivers it again.
