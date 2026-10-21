# Build a mike-versioned static tree (4.0 + 5.0/latest), then serve with nginx.
# Plain `mkdocs build` is NOT enough — Material’s selector needs /versions.json
# and version directories at the site root (same layout as the gh-pages branch).

FROM python:3.13-slim AS builder

# uv binary only; the image build does not need uv on the host.
COPY --from=ghcr.io/astral-sh/uv:0.13.4 /uv /uvx /bin/

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# python:3.13-slim marks the interpreter externally managed. --system targets
# that interpreter so `mike` stays on PATH; --break-system-packages matches
# the image's previous pip install.
RUN uv pip install --system --break-system-packages --no-cache -r requirements.txt

# Clone so both doc branches are available even when the build context
# has no .git (common on hosted Docker builders / Timeweb).
ARG SITE_URL=https://mkdocs.python-cqrs.dev/
ARG REPO_URL=https://github.com/pypatterns/python-cqrs-mkdocs.git
ARG DOCS_5_REF=master
ARG DOCS_4_REF=docs/4.x

RUN git clone --filter=blob:none "$REPO_URL" repo \
    && cd repo \
    && git config user.name "docs-builder" \
    && git config user.email "docs-builder@local" \
    && git checkout "$DOCS_5_REF" \
    && sed -i "s|^site_url:.*|site_url: ${SITE_URL}|" mkdocs.yml \
    && mike deploy --update-aliases 5.0 latest \
    && mike set-default latest \
    && git checkout "$DOCS_4_REF" \
    && sed -i "s|^site_url:.*|site_url: ${SITE_URL}|" mkdocs.yml \
    && mike deploy 4.0 \
    && mkdir -p /out \
    && git archive gh-pages | tar -x -C /out

FROM nginx:alpine

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /out /usr/share/nginx/html

# mike aliases `latest` as a symlink to `5.0`. Some overlay/FS setups
# resolve symlinks poorly; materialize a real copy for reliable serving.
RUN if [ -L /usr/share/nginx/html/latest ]; then \
      target="$(readlink /usr/share/nginx/html/latest)" \
      && rm /usr/share/nginx/html/latest \
      && cp -a "/usr/share/nginx/html/${target}" /usr/share/nginx/html/latest; \
    fi

# Crawlers read these at the host root. mike only emits them inside /latest/.
RUN html=/usr/share/nginx/html \
    && for name in robots.txt sitemap.xml llms.txt llms-full.txt; do \
         test -f "$html/latest/$name" \
         && cp "$html/latest/$name" "$html/$name"; \
       done \
    && if grep -R -l --include='*.html' 'latestllms.txt' "$html/4.0" "$html/5.0"; then \
         echo "alternate link is missing a slash" >&2; \
         exit 1; \
       fi

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
