# Agent skills

Two registries: [skills.sh](https://skills.sh) and [ClawHub](https://clawhub.ai). From your service's project root, not a clone of python-cqrs, either block is enough. Files land in `<app>/.agents/skills/<name>/`.

```bash
npx skills add pypatterns/python-cqrs --skill cqrs-setup -y
npx skills add pypatterns/python-cqrs --skill cqrs-eda -y
npx skills add pypatterns/python-cqrs --skill cqrs-saga -y
npx skills add pypatterns/python-cqrs --skill cqrs-streaming -y
npx skills add pypatterns/python-cqrs --skill cqrs-cor -y
npx skills add pypatterns/python-cqrs --skill cqrs-testing -y
```

```bash
clawhub install @vadikko2/cqrs-setup
clawhub install @vadikko2/cqrs-eda
clawhub install @vadikko2/cqrs-saga
clawhub install @vadikko2/cqrs-streaming
clawhub install @vadikko2/cqrs-cor
clawhub install @vadikko2/cqrs-testing
```

Start with `cqrs-setup`. It is the chooser. The other skills assume that choice and do not repeat it.

The rules page is [Rules for coding agents](https://mkdocs.python-cqrs.dev/latest/agents/index.md). Application authors also copy `templates/AGENTS.md` from the library repository.

## cqrs-setup

Use when writing a command, a query, a domain event, a notification, an outbox, an inbox, a saga, a chain, or a stream.

The skill gives a Use when and a Skip when for each of those features, then the steps that build a command and a query. Both are `cqrs.Request`. There is no `Command` base, no `Query` base, and no `CommandBus`.

An agent that follows it names the feature it picked and the neighbor it skipped, then binds one `cqrs.RequestHandler` and calls `await mediator.send(request)`.

- Skill: [SKILL.md on feat/111-agent-skills](https://github.com/pypatterns/python-cqrs/blob/feat/111-agent-skills/skills/cqrs-setup/SKILL.md)
- Chapter: [Request handlers](https://mkdocs.python-cqrs.dev/latest/request_handler/index.md)

## cqrs-eda

Use when a fact stays in this process, must reach another service, or must survive at-least-once delivery.

The skill builds the feature `cqrs-setup` already picked. A domain event is in-process and finishes before `send` returns. A notification on `events` may be lost. The transactional outbox commits that notification with the business row. The transactional inbox commits the accepted message before the handler runs. Outbox and inbox are not separate skills. Parallel domain handlers are in this skill: `concurrent_event_handle_enable=True` only with `ScopeStrategy.HANDLER` or `ScopeStrategy.NONE`, never with `ScopeStrategy.SEND`.

- Skill: [SKILL.md on feat/111-agent-skills](https://github.com/pypatterns/python-cqrs/blob/feat/111-agent-skills/skills/cqrs-eda/SKILL.md)
- Chapters: [Event handling](https://mkdocs.python-cqrs.dev/latest/event_handler/index.md), [parallel event processing](https://mkdocs.python-cqrs.dev/latest/event_handler/parallel_processing/index.md), [transactional outbox](https://mkdocs.python-cqrs.dev/latest/outbox/index.md), [transactional inbox](https://mkdocs.python-cqrs.dev/latest/inbox/index.md)

## cqrs-saga

Use when a flow crosses services or databases and a completed step must be undone.

The skill builds one `cqrs.SagaStepHandler` with `act` and `compensate`, registers a `cqrs.Saga`, and resumes a crashed run with `cqrs.saga.recovery.recover_saga`. It does not invent `OrchestratedSaga` or `SagaLog`. A single `UPDATE` in one service stays a database transaction. One reliable message stays the outbox.

- Skill: [SKILL.md on feat/111-agent-skills](https://github.com/pypatterns/python-cqrs/blob/feat/111-agent-skills/skills/cqrs-saga/SKILL.md)
- Chapter: [Saga pattern](https://mkdocs.python-cqrs.dev/latest/saga/index.md)

## cqrs-testing

Use when a test must show what a command, a query, a domain event, a notification, an outbox row, an inbox row, a saga step, a chain, a stream, a fallback, or middleware actually did.

The skill names the journal to assert and the neighbor journal that stays empty. A query leaves `handled` and `published` empty. An outbox notification is absent from `published` until `produce_available`. A chain is asserted on `invocations`. The skill does not read `DevnullMessageBroker.MESSAGE_BUS`.

- Skill: [SKILL.md on master](https://github.com/pypatterns/python-cqrs/blob/master/skills/cqrs-testing/SKILL.md)
- Chapter: [Testing](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

## What the agent reads

`SKILL.md` is the permanent context. `references/` and `assets/` are opened from links inside that file. Full demos stay under `examples/` in the library repository and are not copied into the skill.

The application layout the skills ask for is `app/commands.py`, `app/queries.py`, `app/handlers.py`, and `app/bootstrap.py`. Add `app/events.py` only for a domain event, a notification, the outbox, or the inbox. Add `app/sagas.py` only for a saga.

Dependency injection, FastAPI, FastStream, and protobuf stay in their chapters. They are not skills. A missing `message_broker` discards notifications. The durable publish path is the outbox inside `cqrs-eda`.

Do not look for `cqrs-transactional-outbox`, a separate event-handling skill, or `cqrs-parallel-events`. Those names are not published. Parallel domain handlers stay in `cqrs-eda`. Tests stay in `cqrs-testing`.

## Short how-tos

These two do not repeat the chooser. `cqrs-setup` already has their Use when and Skip when pairs. Install them with the command above.

### cqrs-streaming

Use when the caller reads progress before the final answer. Skip when one `send` is enough. The handler is `cqrs.StreamingRequestHandler`. Startup calls `cqrs.bootstrap.requests.bootstrap_streaming`. The caller iterates `async for item in mediator.stream(request)`.

- Skill: [SKILL.md on feat/111-agent-skills](https://github.com/pypatterns/python-cqrs/blob/feat/111-agent-skills/skills/cqrs-streaming/SKILL.md)
- Chapter: [Stream handling](https://mkdocs.python-cqrs.dev/latest/stream_handling/index.md)

### cqrs-cor

Use when a request passes several independent decisions and exactly one should handle it. Skip when every step must run, and skip it for HTTP CORS. Each step is `cqrs.handlers.CORRequestHandler`. A step that does not apply returns `await self.next(request)`. Register the ordered list with one `mapper.bind`.

- Skill: [SKILL.md on feat/111-agent-skills](https://github.com/pypatterns/python-cqrs/blob/feat/111-agent-skills/skills/cqrs-cor/SKILL.md)
- Chapter: [Chain of responsibility](https://mkdocs.python-cqrs.dev/latest/chain_of_responsibility/index.md)
