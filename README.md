# python-cqrs-mkdocs
Python CQRS [framework](https://github.com/vadikko2/python-cqrs) documentation.

## Development
### Install requirements
```bash
pip install -r ./requirements.txt
```
### Setting pre-commit
```bash
pre-commit install
```

### Run server
```bash
mkdocs serve
```

## Versioning

Docs are versioned with **mike** (`4.0` from `docs/4.x`, `5.0`/`latest` from `master`). See [VERSIONING.md](VERSIONING.md) for the deploy matrix and the one-time `gh-pages` migration note (do **not** run `mike delete --all` in CI).

## Deployment
Canonical `site_url` is `https://mkdocs.python-cqrs.dev/` (Timeweb). Keep it aligned with the public docs host so Material’s mike version selector works.

- **Timeweb (Docker)** — `Dockerfile` builds a **versioned** site with mike (`4.0` + `5.0`/`latest`) and serves it via nginx. Redeploy the container after pushes so `/versions.json` exists on the live host.
- **GitHub Pages** — CI runs `mike deploy --push` to `gh-pages` (mirror). Same `site_url` as Timeweb.
- See [VERSIONING.md](VERSIONING.md) for the branch → version matrix and cutover notes.
