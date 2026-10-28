---
title: Agent skills
description: Skills that tell a coding agent which python-cqrs feature to use and which API to call.
---

# Agent skills

These skills live in the library repository, under `skills/<name>/`. They are not part of the wheel. `pip install python-cqrs` does not copy them into the virtualenv, and an agent should not search `site-packages` for `SKILL.md`.

Run the commands from the application root. The source is the `master` branch of `pypatterns/python-cqrs`, not the tag of the installed package. Version 5.3.1 of the package does not contain these files. The skills describe the current 5.x API.

```bash
npx skills add pypatterns/python-cqrs --skill cqrs-setup -a cursor -y
npx skills add pypatterns/python-cqrs --skill cqrs-eda -a cursor -y
npx skills add pypatterns/python-cqrs --skill cqrs-saga -a cursor -y
npx skills add pypatterns/python-cqrs --skill cqrs-streaming -a cursor -y
npx skills add pypatterns/python-cqrs --skill cqrs-cor -a cursor -y
```

A local install with `-a cursor` copies each skill to `.agents/skills/<name>/` under that root. The files are copies, not symlinks. Installing the next skill does not replace the ones already there. Public installation comes from the `pypatterns/python-cqrs` repository. A skills.sh listing appears after installations from that repository. Installing a local checkout does not create that listing, and CI does not publish it.

[ClawHub](https://clawhub.ai) is a separate publish. The `npx skills add` commands above do not publish there. After these skills are on `master`, check out that commit of `pypatterns/python-cqrs` and publish the folders under `skills/` with the ClawHub CLI. Run it on that checkout. Do not run it from CI. `sync` publishes those folders and does not report install telemetry. The slug is the folder name: `cqrs-setup`, `cqrs-eda`, `cqrs-saga`, `cqrs-streaming`, or `cqrs-cor`. A skill published this way is released under MIT-0 on ClawHub.

```bash
npm i -g clawhub
clawhub login
clawhub whoami
clawhub sync --root ./skills --all --dry-run
clawhub sync --root ./skills --all
```

Pass `--owner <owner>` on both `sync` commands only when that publisher handle already exists and this account can publish for it. Omit `--owner` to publish as the signed-in user. New skills start at `1.0.0`.

After that publish, an application installs from its root with `clawhub install @<owner>/<slug>`. `<owner>` is the publisher handle from `whoami` or from `--owner`. `<slug>` is the skill folder name. These commands are the maintainer publish and the later install. They are not a claim that ClawHub already lists the skills.

Start with `cqrs-setup`. It is the chooser. The other skills assume that choice and do not repeat it.

The rules page is [Rules for coding agents](agents.md). Application authors also copy `templates/AGENTS.md` from the library repository.

## cqrs-setup

Use when writing a command, a query, a domain event, a notification, an outbox, an inbox, a saga, a chain, or a stream.

The skill gives a Use when and a Skip when for each of those features, then the steps that build a command and a query. Both are `cqrs.Request`. There is no `Command` base, no `Query` base, and no `CommandBus`.

An agent that follows it names the feature it picked and the neighbor it skipped, then binds one `cqrs.RequestHandler` and calls `await mediator.send(request)`.

- Skill: [SKILL.md on feat/111-agent-skills](https://github.com/pypatterns/python-cqrs/blob/feat/111-agent-skills/skills/cqrs-setup/SKILL.md)
- Chapter: [Request handlers](request_handler/index.md)

## cqrs-eda

Use when a fact stays in this process, must reach another service, or must survive at-least-once delivery.

The skill builds the feature `cqrs-setup` already picked. A domain event is in-process and finishes before `send` returns. A notification on `events` may be lost. The transactional outbox commits that notification with the business row. The transactional inbox commits the accepted message before the handler runs. Outbox and inbox are not separate skills. Parallel domain handlers are in this skill: `concurrent_event_handle_enable=True` only with `ScopeStrategy.HANDLER` or `ScopeStrategy.NONE`, never with `ScopeStrategy.SEND`.

- Skill: [SKILL.md on feat/111-agent-skills](https://github.com/pypatterns/python-cqrs/blob/feat/111-agent-skills/skills/cqrs-eda/SKILL.md)
- Chapters: [Event handling](event_handler/index.md), [parallel event processing](event_handler/parallel_processing.md), [transactional outbox](outbox/index.md), [transactional inbox](inbox/index.md)

## cqrs-saga

Use when a flow crosses services or databases and a completed step must be undone.

The skill builds one `cqrs.SagaStepHandler` with `act` and `compensate`, registers a `cqrs.Saga`, and resumes a crashed run with `cqrs.saga.recovery.recover_saga`. It does not invent `OrchestratedSaga` or `SagaLog`. A single `UPDATE` in one service stays a database transaction. One reliable message stays the outbox.

- Skill: [SKILL.md on feat/111-agent-skills](https://github.com/pypatterns/python-cqrs/blob/feat/111-agent-skills/skills/cqrs-saga/SKILL.md)
- Chapter: [Saga pattern](saga/index.md)

## What the agent reads

`SKILL.md` is the permanent context. `references/` and `assets/` are opened from links inside that file. Full demos stay under `examples/` in the library repository and are not copied into the skill.

The application layout the skills ask for is `app/commands.py`, `app/queries.py`, `app/handlers.py`, and `app/bootstrap.py`. Add `app/events.py` only for a domain event, a notification, the outbox, or the inbox. Add `app/sagas.py` only for a saga.

Dependency injection, FastAPI, FastStream, and protobuf stay in their chapters. They are not skills. A missing `message_broker` discards notifications. The durable publish path is the outbox inside `cqrs-eda`.

Do not look for `cqrs-transactional-outbox`, a separate event-handling skill, or `cqrs-parallel-events`. Those names are not published. Parallel domain handlers stay in `cqrs-eda`.

## Short how-tos

These two do not repeat the chooser. `cqrs-setup` already has their Use when and Skip when pairs. Install them with the commands above.

### cqrs-streaming

Use when the caller reads progress before the final answer. Skip when one `send` is enough.
The handler is `cqrs.StreamingRequestHandler`. Startup calls `cqrs.bootstrap.requests.bootstrap_streaming`. The caller iterates `async for item in mediator.stream(request)`.

- Skill: [SKILL.md on feat/111-agent-skills](https://github.com/pypatterns/python-cqrs/blob/feat/111-agent-skills/skills/cqrs-streaming/SKILL.md)
- Chapter: [Stream handling](stream_handling/index.md)

### cqrs-cor

Use when a request passes several independent decisions and exactly one should handle it. Skip when every step must run, and skip it for HTTP CORS.
Each step is `cqrs.handlers.CORRequestHandler`. A step that does not apply returns `await self.next(request)`. Register the ordered list with one `mapper.bind`.

- Skill: [SKILL.md on feat/111-agent-skills](https://github.com/pypatterns/python-cqrs/blob/feat/111-agent-skills/skills/cqrs-cor/SKILL.md)
- Chapter: [Chain of responsibility](chain_of_responsibility/index.md)
