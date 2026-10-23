---
title: Transactional inbox examples
description: SQLite drain, FastAPI 202, and a FastStream batch subscriber for the transactional inbox.
---

# Examples

The runnable script is [`examples/inbox/process_deposits.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/inbox/process_deposits.py). It uses SQLite and no broker. `add` receives three items, two with the same message id, and returns `[True, False, True]`. The accept path opens a session, writes the batch, commits, and closes. The worker then opens its own session and calls `get_many(batch_size=2)` until the batch is empty. The handler and the inbox repository share that session for one batch, and the loop commits it. The ledger has two rows, `acc-1` and `acc-2`. A second drain gets an empty batch because both rows are `processed`.

```python
async def accept_deposits() -> list[bool]:
    async with SessionLocal() as session:
        inbox = cqrs.SqlAlchemyInboxRepository(session, message_map=MESSAGE_MAP)
        stored = await inbox.add(
            [
                ("msg-1", ProcessDeposit(account_id="acc-1", amount="10.00")),
                ("msg-1", ProcessDeposit(account_id="acc-1", amount="10.00")),
                ("msg-2", ProcessDeposit(account_id="acc-2", amount="5.00")),
            ],
        )
        await session.commit()
        return stored
```

```python
async def drain_inbox(batch_size: int = 2) -> int:
    processed = 0
    while True:
        async with SessionLocal() as session:
            inbox = cqrs.SqlAlchemyInboxRepository(session, message_map=MESSAGE_MAP)
            rows = await inbox.get_many(batch_size=batch_size)
            if not rows:
                return processed
            processor = cqrs.InboxProcessor(
                inbox,
                MESSAGE_MAP,
                request_mediator=mediator_for(session),
            )
            for row in rows:
                await processor.process(row)
            await session.commit()
            processed += len(rows)
```

`mediator_for(session)` builds the `RequestMediator` so the registered handler receives that same session. The handler is an ordinary `RequestHandler`. It does not know about the inbox and it does not commit:

```python
class ProcessDepositHandler(cqrs.RequestHandler[ProcessDeposit, None]):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def handle(self, request: ProcessDeposit) -> None:
        self._session.add(LedgerRow(account_id=request.account_id, amount=request.amount))
```

```bash
pip install -e ".[examples]"
python examples/inbox/process_deposits.py
```

A production reader uses the same loop, sleeps on an empty batch, and does not return. That process is separate from the subscriber, the same way [outbox publishing](../outbox/examples.md) is separate from the command that wrote the row.

## FastAPI

[`examples/inbox/fastapi_accept.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/inbox/fastapi_accept.py) puts one command or one event in a batch of length 1 and returns 202. `inbox_repository` opens the session, yields `SqlAlchemyInboxRepository`, commits when the route returns, and rolls back when the route raises. The route calls `add`. It does not call a mediator. Repeating the idempotency key is still 202.

```python
async def inbox_repository() -> typing.AsyncIterator[cqrs.InboxRepository]:
    session = SessionLocal()
    try:
        yield cqrs.SqlAlchemyInboxRepository(session, message_map=MESSAGE_MAP)
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()


@app.post("/deposits", status_code=202)
async def accept_deposit(
    body: ProcessDeposit,
    idempotency_key: str = fastapi.Header(alias="Idempotency-Key"),
    inbox: cqrs.InboxRepository = fastapi.Depends(inbox_repository),
) -> dict:
    await inbox.add([(idempotency_key, body)])
    return {"accepted": True}
```

## FastStream

[`examples/inbox/faststream_accept.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/inbox/faststream_accept.py) uses FastStream 0.5 (`faststream[kafka]==0.5.28`). `batch=True` collects the Kafka records. `faststream.Depends(inbox_repository)` injects the same generator. The whole list goes to one `add`. FastStream acks the batch after that generator commits.

```python
@broker.subscriber(
    "account-deposits",
    batch=True,
    max_records=500,
    auto_commit=False,
    group_id="deposits-inbox",
)
async def on_deposits(
    bodies: list[dict],
    message: kafka.KafkaMessage,
    inbox: cqrs.InboxRepository = faststream.Depends(inbox_repository),
) -> None:
    records = message.raw_message
    if not isinstance(records, tuple):
        records = (records,)
    await inbox.add(
        [
            (
                f"{record.offset}-{record.timestamp}",
                ProcessDeposit(
                    account_id=body["account_id"],
                    amount=body["amount"],
                ),
            )
            for body, record in zip(bodies, records)
        ],
    )
```

## Another row in the same accept transaction

[`examples/inbox/presentation_scope.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/inbox/presentation_scope.py) is the extra case, not the default. Use it when the presentation must write the inbox row and a second row in the same transaction. `open_scope` and `bind_scope` keep both writes on one `AsyncSession`. The provider commits both when the scope exits, or rolls both back when it raises. The processor does not join this session. A route that only stores the message uses `Depends(inbox_repository)` and `add`, as in the FastAPI section above.
