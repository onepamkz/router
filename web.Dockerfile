ARG VERSION=v4.10.16

# ── Lina (Vue.js) ─────────────────────────────────────────────────────────────
FROM node:20-bullseye-slim AS lina
COPY corp-ca.pem /tmp/corp-ca.pem
ENV NODE_EXTRA_CA_CERTS=/tmp/corp-ca.pem
WORKDIR /app
COPY sources/lina/ .
RUN yarn install
RUN yarn build

# ── Luna (Angular web terminal) ───────────────────────────────────────────────
FROM node:20-bullseye-slim AS luna
COPY corp-ca.pem /tmp/corp-ca.pem
ENV NODE_EXTRA_CA_CERTS=/tmp/corp-ca.pem
WORKDIR /app
COPY sources/luna/ .
RUN yarn install
RUN yarn build
RUN cp -R src/assets/i18n dist/

# ── Final web image ───────────────────────────────────────────────────────────
FROM jumpserver/web:${VERSION}-ce
COPY --from=lina /app/lina/ /opt/lina/
COPY --from=luna /app/dist/ /opt/luna/
