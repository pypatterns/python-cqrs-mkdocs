---
title: Rules for coding agents
description: How an agent should use python-cqrs — Request[Result], one handler per request, no CommandBus.
---

# Rules for coding agents

These rules are for an agent writing an application on `python-cqrs` 5.2 or newer. They are also the first section of `llms.txt`.

## Where the skills are installed

`pip install python-cqrs` does not install the skills. Run this in your application root, not from a clone of `pypatterns/python-cqrs` and not from an empty directory. `npx` copies `cqrs-setup`, `cqrs-eda`, `cqrs-saga`, `cqrs-streaming`, and `cqrs-cor` from the `master` branch of that GitHub repository, not from the installed package version:

```bash
npx skills add pypatterns/python-cqrs --skill cqrs-setup cqrs-eda cqrs-saga cqrs-streaming cqrs-cor -y
```

The files land in `<app>/.agents/skills/<name>/`. The coding agent in that project reads them from there.

To add an already published skill to the application, from that same root, run `clawhub install @<owner>/<slug>`. `<slug>` is one of those five names.

A maintainer publishes from a clone of this repository after `clawhub login`:

```bash
clawhub sync --root ./skills --all
```

The longer catalog is [Agent skills](skills.md).

## Requests and handlers

- Commands and queries are both `cqrs.Request`. There is no `Query` class and no `CommandBus`.
- There is no `register_handler` decorator. Register with `mapper.bind(RequestType, Handler)`.
- One handler per request type. A second `bind` for the same request raises `KeyError`.
- An event may have many handlers. `EventMap.bind` appends.

## Types to copy

A request that returns data:

```python
class ReadMeetingQueryResult(cqrs.Response):
    users: list[str]

class ReadMeetingQuery(cqrs.Request[ReadMeetingQueryResult]):
    meeting_id: str

class ReadMeetingQueryHandler(cqrs.RequestHandler[ReadMeetingQuery]):
    async def handle(self, request: ReadMeetingQuery):
        return ReadMeetingQueryResult(users=["1", "2"])
```

Do not add `-> ReadMeetingQueryResult` on `handle`. `await mediator.send(query)` is `ReadMeetingQueryResult`.

A command with an empty body:

```python
class JoinMeetingCommand(cqrs.Request[None]):
    user_id: str
    meeting_id: str

class JoinMeetingCommandHandler(cqrs.RequestHandler[JoinMeetingCommand]):
    async def handle(self, request: JoinMeetingCommand):
        print(request.user_id, request.meeting_id)
```

`handle` returns `None`. Do not annotate it.

Legacy (still supported): `RequestHandler[Request, Result]` with a return annotation on `handle` still works and is not the form to copy. Do not rewrite existing handlers. `send` on an unparameterized `Request` is `Any`.

The same parameter types a stream element (`StreamingRequestHandler[Command]` with `Request[ItemResult]`) and `PydanticRequest[Result]` when the `pydantic` extra is installed.

## What the library does not check

- A read handler should not write state and should not fill `events`. A command handler may. The library does not enforce that.
- Publish to a broker through the transactional outbox. Do not write the business row and then publish to the broker in the same handler.
- A broker or HTTP endpoint that only accepts a command or event opens a session, writes `InboxRepository.add([(message_id, message)])`, and commits. `add` always takes a batch and returns `list[bool]`. A duplicate is `False` and still ends as ack or HTTP 202. Construct `InboxProcessor` with the repository for the worker session. `process` takes the row. It calls `get_many` and the mediator that is already registered. The handler does not commit. The caller owns the session and the commit. Do not call `mediator.send` in that subscriber or route. Do not share the presentation session with the processor. `open_scope` and `bind_scope` are only when that same presentation transaction must also write another row.
- Use a saga for a step that has compensation across services, not for a single `UPDATE`.

## Extras

Install extras explicitly: `pydantic`, `sqlalchemy`, `sqlmodel`, `kafka`, and the others listed in the library `pyproject.toml`.

## Examples

- [Request handler](https://github.com/vadikko2/python-cqrs/blob/master/examples/events/typed_request_handler.py)
- [Streaming handler](https://github.com/vadikko2/python-cqrs/blob/master/examples/streaming/typed_streaming_handler.py)
- [Chain of responsibility](https://github.com/vadikko2/python-cqrs/blob/master/examples/cor/typed_cor_request_handler.py)
- [Transactional inbox](https://github.com/vadikko2/python-cqrs/blob/master/examples/inbox/process_deposits.py)

Further reading: [Request handlers](request_handler/index.md), [streaming](stream_handling/index.md), [chain of responsibility](chain_of_responsibility/index.md).
