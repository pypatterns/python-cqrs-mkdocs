# Upgrade to python-cqrs 5.x

You are on **4.x** documentation. Version **5.0** is released with breaking changes. Full detail lives in the 5.0 docs migration guide; this page is the checklist for clients still on 4.x.

Upstream discussion: [GitHub #57](https://github.com/vadikko2/python-cqrs/discussions/57).

## Stay on 4.x for now

```bash
pip install "python-cqrs>=4,<5"
```

The **4.x** line receives bug fixes and security patches for about **12 months** after 5.0.0. See the library [SECURITY.md](https://github.com/pypatterns/python-cqrs/blob/4.x/SECURITY.md).

## When you are ready for 5.0

```bash
pip install "python-cqrs[pydantic,sqlalchemy]"   # close to previous default stack
# or
pip install python-cqrs                            # dataclasses-only core
```

### Breaking changes (checklist)

1. **Defaults are dataclasses** — `Request` / `Response` / `Event` / `DomainEvent` / `NotificationEvent` alias to `DC*`. Use `Pydantic*` from `cqrs.models.pydantic` (extra `[pydantic]`) when you need validation.
2. **Optional SQLAlchemy** — outbox / saga SQLAlchemy modules need `pip install python-cqrs[sqlalchemy]`.
3. **Package layout (hard break, no shims)** — see table below.
4. **`SagaMediator.stream` → `execute`** — same signature; `StreamingRequestMediator.stream` is unchanged.
5. **Optional empty `events`** — already optional since 4.15; no change required.

### Import path table

| 4.x | 5.0 |
|-----|-----|
| `cqrs.requests.bootstrap` | `cqrs.bootstrap.requests` |
| `cqrs.events.bootstrap` | `cqrs.bootstrap.events` |
| `cqrs.saga.bootstrap` | `cqrs.bootstrap.saga` |
| `cqrs.mediator` | `cqrs.mediators` |
| `cqrs.requests.request_handler` | `cqrs.handlers.request` |
| `cqrs.requests.cor_request_handler` | `cqrs.handlers.cor` |
| `cqrs.events.event_handler` | `cqrs.handlers.event` |
| `cqrs.saga.step` | `cqrs.handlers.saga` |
| `cqrs.requests.request` / `cqrs.response` / `cqrs.events.event` | `cqrs.models.*` |
| `cqrs.requests.map` / `cqrs.events.map` / `cqrs.outbox.map` | `cqrs.mapping.*` |
| `cqrs.requests.mermaid` / `cqrs.saga.mermaid` | `cqrs.mermaid.*` |
| `cqrs.producer.EventProducer` | `cqrs.message_brokers.producer.EventProducer` |

Open the **5.0 / latest** docs via the version selector (or `/5.0/migration/4-to-5/`) for the canonical guide after deploy.
