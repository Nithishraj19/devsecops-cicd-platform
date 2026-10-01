# syntax=docker/dockerfile:1
FROM node:22-alpine AS dependencies
WORKDIR /srv/app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force
FROM node:22-alpine AS runtime
ARG APP_VERSION=1.0.0
ENV NODE_ENV=production PORT=3000 APP_VERSION=$APP_VERSION
# The runtime needs Node only; remove bundled npm, corepack, and Yarn package trees.
RUN rm -rf /usr/local/lib/node_modules/npm /opt/yarn-* /usr/local/lib/node_modules/corepack && rm -f /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack /usr/local/bin/yarn /usr/local/bin/yarnpkg
WORKDIR /srv/app
COPY --from=dependencies --chown=node:node /srv/app/node_modules ./node_modules
COPY --chown=node:node src ./src
COPY --chown=node:node package.json ./package.json
USER node
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 CMD node -e "fetch('http://127.0.0.1:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "src/server.js"]
