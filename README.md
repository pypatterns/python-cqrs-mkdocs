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
Стили и скрипты подключаются корректно только если в `mkdocs.yml` указан **тот же** `site_url`, что и фактический URL сайта после деплоя.

- **Timeweb (Docker)** — в репозитории уже задан `site_url: https://mkdocs.python-cqrs.dev/`; сборка через Docker использует его как есть.
- **GitHub Pages** — в CI перед сборкой подставляется `site_url` для `https://vadikko2.github.io/python-cqrs-mkdocs/`, затем `mike deploy`.
- Другой домен/подпуть — задайте свой `site_url` в `mkdocs.yml` (с завершающим слешем) или подменяйте его при сборке.
