# Transactional Inbox

The inbox is the inbound side of the [transactional outbox](https://mkdocs.python-cqrs.dev/latest/outbox/index.md). A broker delivers at-least-once. The presentation layer stores the command or event, commits that short transaction, and only then acknowledges the transport. A separate process reads the row and calls the mediator that is already registered.

Coding agents build the inbox with [cqrs-eda](https://github.com/pypatterns/python-cqrs/blob/feat/111-agent-skills/skills/cqrs-eda/SKILL.md). It is not a separate skill. The catalog is [Agent skills](https://mkdocs.python-cqrs.dev/latest/skills/index.md).

## Two steps

| Step           | Who                                    | What                                                            |
| -------------- | -------------------------------------- | --------------------------------------------------------------- |
| **1. Accept**  | FastAPI route or FastStream subscriber | `InboxRepository.add([(message_id, message)])`, then commit     |
| **2. Process** | `InboxProcessor` in another process    | `get_many`, then `RequestMediator.send` or `EventMediator.send` |

The handler that runs in step 2 is the one bound on `RequestMap` or `EventMap`. The inbox does not add a handler whose only job is to insert the row, and it is not middleware. Middleware receives `(request, handle)` and runs inside `RequestDispatcher`. An event consumer and a route that must answer before the handler finishes never enter that chain.

```
sequenceDiagram
    participant Edge as Presentation
    participant Inbox as InboxRepository
    participant DB
    participant Worker as InboxProcessor
    participant Mediator
    participant Handler

    Edge->>Inbox: add message_id and command or event
    Inbox->>DB: insert status new
    Edge->>DB: commit
    Note over Edge: then ack broker or return 202
    loop separate process
        Worker->>Inbox: get_many SKIP LOCKED
        Worker->>Mediator: send deserialized message
        Mediator->>Handler: existing handler
        Handler->>DB: business rows
        Worker->>Inbox: status processed
        Worker->>DB: commit business and status together
    end
```

`message_id` comes from the application: a Kafka message id, a header, or `Idempotency-Key`. The framework does not read broker headers.

A repeat delivery inserts no second row. `add` returns `False` for that element and leaves the transaction usable, so the subscriber still acknowledges.

## What this is not

- Not a `Command` base and not `IdempotentCommand`. Commands and queries stay `cqrs.Request`.
- Not a handler, middleware, or mediator method that only writes the inbox row.
- Not one transaction that both accepts the message and applies the business change. The processor applies that change in a later session.
- Not a stored HTTP response. A repeated request gets `202` again, not the handler's previous JSON.

See [Usage](https://mkdocs.python-cqrs.dev/latest/inbox/usage/index.md) for `add`, the name map, and the accept session versus the worker session. See [Examples](https://mkdocs.python-cqrs.dev/latest/inbox/examples/index.md) for the SQLite drain and the FastAPI and FastStream fragments.
