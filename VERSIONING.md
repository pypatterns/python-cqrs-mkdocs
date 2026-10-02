# Documentation versioning (mike)

This site uses [mike](https://github.com/jimporter/mike) with MkDocs Material’s version selector.

| Git branch   | mike version | Aliases   |
|--------------|--------------|-----------|
| `master`     | `5.0`        | `latest` (default) |
| `docs/4.x`   | `4.0`        | —         |

CI (`.github/workflows/ci.yaml`) runs `mike deploy --push` instead of `mkdocs gh-deploy --force`, so version directories are not wiped on every push.

## One-time migration from unversioned gh-pages

The previous deploy used `mkdocs gh-deploy --force` (flat site root). Moving to mike requires a **manual, one-time** cutover:

1. Back up the live `gh-pages` branch (clone or archive), including any `CNAME` / custom 404 assets.
2. Optionally snapshot the current unversioned HTML elsewhere.
3. Only after backup, you may run `mike delete --all` locally against `gh-pages` if you need a clean slate — **do not** put `mike delete --all` in CI.
4. Deploy once from each branch:
   - `master` → `mike deploy --push --update-aliases 5.0 latest` then `mike set-default --push latest`
   - `docs/4.x` → `mike deploy --push 4.0`
5. Restore `CNAME` (and any host-specific files) if mike/gh-pages lost them.
6. Point Timeweb (`mkdocs.python-cqrs.dev`) at the same versioned tree (or mirror `gh-pages`); keep a single canonical `site_url`.

Until that cutover, the first mike deploy from CI may coexist with or replace the old layout depending on the existing `gh-pages` contents — coordinate the migration deliberately.
