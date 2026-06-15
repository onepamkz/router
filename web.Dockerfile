ARG VERSION=v3.10.7

# ── Lina (Vue.js) ─────────────────────────────────────────────────────────────
FROM node:16-bullseye-slim AS lina
COPY corp-ca.pem /tmp/corp-ca.crt
RUN apt-get update -qq && apt-get install -y --no-install-recommends ca-certificates \
    && cp /tmp/corp-ca.crt /usr/local/share/ca-certificates/corp-ca.crt \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY sources/lina/ .
RUN yarn install
RUN yarn build

# ── Luna (Angular 8 web terminal) ─────────────────────────────────────────────
FROM node:16-bullseye-slim AS luna
COPY corp-ca.pem /tmp/corp-ca.crt
RUN apt-get update -qq && apt-get install -y --no-install-recommends ca-certificates \
    && cp /tmp/corp-ca.crt /usr/local/share/ca-certificates/corp-ca.crt \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY sources/luna/ .
RUN yarn install
RUN yarn build
RUN cp -R src/assets/i18n dist/

# ── Final web image ───────────────────────────────────────────────────────────
FROM jumpserver/web:${VERSION}
COPY --from=lina /app/lina/ /opt/lina/
COPY --from=luna /app/dist/ /opt/luna/
