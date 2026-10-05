# Documentation versioning (mike)

This site uses [mike](https://github.com/jimporter/mike) with MkDocs Material’s version selector.

| Git branch   | mike version | Aliases   |
|--------------|--------------|-----------|
| `master`     | `5.0`        | `latest` (default) |
| `docs/4.x`   | `4.0`        | —         |

## Deploy targets

| Target | How it is updated |
|--------|-------------------|
| **Timeweb** `https://mkdocs.python-cqrs.dev/` (canonical) | Docker image builds a **mike-versioned** tree (`Dockerfile` clones `master` + `docs/4.x`, runs `mike deploy`, serves the result with nginx). Rebuild/redeploy the container after doc pushes. |
| **GitHub Pages** `https://pypatterns.github.io/python-cqrs-mkdocs/` | CI (`.github/workflows/ci.yaml`) runs `mike deploy --push` to the `gh-pages` branch. |

`site_url` in `mkdocs.yml` stays `https://mkdocs.python-cqrs.dev/` for both builds so Material’s version switcher resolves correctly on the canonical host.

CI must **not** use `mkdocs gh-deploy --force` (that wipes version directories). Do **not** put `mike delete --all` in CI.

## One-time migration from unversioned layout

The previous Timeweb image ran plain `mkdocs build` (flat site root). GitHub Pages may still have leftover flat directories beside `4.0/` / `5.0/` from the pre-mike era.

1. Back up live `gh-pages` (and any Timeweb volume), including custom assets if any.
2. Ensure CI has published both versions:
   - `master` → `mike deploy --push --update-aliases 5.0 latest` then `mike set-default --push latest`
   - `docs/4.x` → `mike deploy --push 4.0`
3. Optionally remove orphan **root-level** flat paths on `gh-pages` (everything except `.nojekyll`, `404.html`, `index.html`, `versions.json`, `4.0/`, `5.0/`, `latest`). Prefer a careful manual cleanup over `mike delete --all`.
4. Rebuild/redeploy the Timeweb App from `master` (Dockerfile builds the mike tree). Autodeploy should pick up the push; otherwise trigger Deploy in the Timeweb panel.
5. Confirm `https://mkdocs.python-cqrs.dev/versions.json` returns 4.0 + 5.0 and the header **Select version** dropdown shows both releases.

As of 2026-10-05 this cutover is done on production: root redirects to `/latest/`, and `/versions.json` lists `5.0` (alias `latest`) and `4.0`.
