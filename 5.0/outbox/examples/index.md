# Examples

- **Back to Transactional Outbox Overview**

  Return to the Transactional Outbox overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/outbox/index.md)

______________________________________________________________________

## Overview

Here's a complete example showing the outbox pattern:

```python
import asyncio
import di
import cqrs
from cqrs.bootstrap import requests as bootstrap
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

# Register events
class UserJoinedPayload(cqrs.BaseModel, frozen=True):
    user_id: str
    meeting_id: str

cqrs.OutboxedEventMap.register(
    "user_joined",
    cqrs.NotificationEvent[UserJoinedPayload],
)

# Command handler
class JoinMeetingCommand(cqrs.Request):
    user_id: str
    meeting_id: str

class JoinMeetingCommandHandler(cqrs.RequestHandler[JoinMeetingCommand, None]):
    def __init__(self, outbox: cqrs.OutboxedEventRepository):
        self.outbox = outbox

    @property
    def events(self) -> list[cqrs.Event]:
        return []

    async def handle(self, request: JoinMeetingCommand) -> None:
        # Business logic
        print(f"User {request.user_id} joined meeting {request.meeting_id}")

        # Save event to outbox
        self.outbox.add(
            cqrs.NotificationEvent[UserJoinedPayload](
                event_name="user_joined",
                topic="user_events",
                payload=UserJoinedPayload(
                    user_id=request.user_id,
                    meeting_id=request.meeting_id,
                ),
            )
        )

        # Commit transaction
        await self.outbox.commit()

# Setup DI
def setup_di():
    container = di.Container()
    session_factory = async_sessionmaker(
        create_async_engine("mysql+asyncmy://user:pass@localhost/db")
    )

    container.bind(
        di.bind_by_type(
            di.Dependent(
                lambda: cqrs.SqlAlchemyOutboxedEventRepository(
                    session=session_factory(),
                ),
                scope="request",
            ),
            cqrs.OutboxedEventRepository,
        )
    )
    return container

# Bootstrap
mediator = bootstrap.bootstrap(
    di_container=setup_di(),
    commands_mapper=lambda m: m.bind(JoinMeetingCommand, JoinMeetingCommandHandler),
)

# Use mediator
await mediator.send(JoinMeetingCommand(user_id="123", meeting_id="456"))
```

## Protobuf outbox (opt-in)

JSON remains the default codec. To store and publish selected events as Protobuf, register a `ProtobufEventSerializer` on an isolated `OutboxedEventMap` and pass that map into the repository.

Runnable produce + consume (no Kafka):

```bash
pip install -e ".[examples]"
python examples/outbox/protobuf_outbox.py
```

Full walkthrough: [Protobuf Integration](https://mkdocs.python-cqrs.dev/latest/protobuf/index.md). Source: [protobuf_outbox.py](https://github.com/vadikko2/python-cqrs/blob/master/examples/outbox/protobuf_outbox.py).
