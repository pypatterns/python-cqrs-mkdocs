# Build a mike-versioned static tree (4.0 + 5.0/latest), then serve with nginx.
# Plain `mkdocs build` is NOT enough — Material’s selector needs /versions.json
# and version directories at the site root (same layout as the gh-pages branch).

FROM python:3.13-slim AS builder

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

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

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
