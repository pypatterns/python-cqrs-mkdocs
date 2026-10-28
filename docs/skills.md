---
title: Agent skills
description: Skills that tell a coding agent which python-cqrs feature to use and which API to call.
---

# Agent skills

These skills live in the library repository, under `skills/<name>/`. They are not part of the wheel. `pip install python-cqrs` does not copy them into the virtualenv, and an agent should not search `site-packages` for `SKILL.md`.

Run the commands from the application root. The source is the `master` branch of `pypatterns/python-cqrs`, not the tag of the installed package. Version 5.3.1 of the package does not contain these files. The skills describe the current 5.x API.

```bash
npx skills add pypatterns/python-cqrs --skill cqrs-core-setup -a cursor -y
npx skills add pypatterns/python-cqrs --skill cqrs-event-driven -a cursor -y
npx skills add pypatterns/python-cqrs --skill cqrs-saga-orchestration -a cursor -y
```

A local install with `-a cursor` copies each skill to `.agents/skills/<name>/` under that root. The files are copies, not symlinks. Installing the next skill does not replace the ones already there. Public installation comes from the `pypatterns/python-cqrs` repository. A skills.sh listing appears after such installations.

Start with `cqrs-core-setup`. It is the chooser. The other skills assume that choice and do not repeat it.

The rules page is [Rules for coding agents](agents.md). Application authors also copy `templates/AGENTS.md` from the library repository.

## cqrs-core-setup

Use when writing a command, a query, a domain event, a notification, an outbox, an inbox, a saga, a chain, or a stream.

The skill gives a Use when and a Skip when for each of those features, then the steps that build a command and a query. Both are `cqrs.Request`. There is no `Command` base, no `Query` base, and no `CommandBus`.

An agent that follows it names the feature it picked and the neighbor it skipped, then binds one `cqrs.RequestHandler` and calls `await mediator.send(request)`.

- Skill: [SKILL.md on master](https://github.com/pypatterns/python-cqrs/blob/master/skills/cqrs-core-setup/SKILL.md)
- Chapter: [Request handlers](request_handler/index.md)

## cqrs-event-driven

Use when a fact stays in this process, must reach another service, or must survive at-least-once delivery.

The skill builds the feature `cqrs-core-setup` already picked. A domain event is in-process and finishes before `send` returns. A notification on `events` may be lost. The transactional outbox commits that notification with the business row. The transactional inbox commits the accepted message before the handler runs. Outbox and inbox are not separate skills.

- Skill: [SKILL.md on master](https://github.com/pypatterns/python-cqrs/blob/master/skills/cqrs-event-driven/SKILL.md)
- Chapters: [Event handling](event_handler/index.md), [transactional outbox](outbox/index.md), [transactional inbox](inbox/index.md)

## cqrs-saga-orchestration

Use when a flow crosses services or databases and a completed step must be undone.

The skill builds one `cqrs.SagaStepHandler` with `act` and `compensate`, registers a `cqrs.Saga`, and resumes a crashed run with `cqrs.saga.recovery.recover_saga`. It does not invent `OrchestratedSaga` or `SagaLog`. A single `UPDATE` in one service stays a database transaction. One reliable message stays the outbox.

- Skill: [SKILL.md on master](https://github.com/pypatterns/python-cqrs/blob/master/skills/cqrs-saga-orchestration/SKILL.md)
- Chapter: [Saga pattern](saga/index.md)

## What the agent reads

`SKILL.md` is the permanent context. `references/` and `assets/` are opened from links inside that file. Full demos stay under `examples/` in the library repository and are not copied into the skill.

The application layout the skills ask for is `app/commands.py`, `app/queries.py`, `app/handlers.py`, and `app/bootstrap.py`. Add `app/events.py` only for a domain event, a notification, the outbox, or the inbox. Add `app/sagas.py` only for a saga.

Dependency injection, FastAPI, FastStream, and protobuf stay in their chapters. They are not skills. A missing `message_broker` discards notifications. The durable publish path is the outbox inside `cqrs-event-driven`.

Do not look for `cqrs-transactional-outbox` or a separate event-handling skill. Those names are not published.
