# Demo API

A small Node.js service for exercising the parent DevSecOps pipeline.

## Routes

- GET /health — lifecycle status and deployed version
- GET /version — application version and runtime environment
- GET / — service metadata and route links

## Local use

    npm ci
    npm test
    npm run lint
    APP_VERSION=1.0.0 PORT=3000 npm start

## Container

From the repository root:

    docker build -t devsecops-demo-api:local --build-arg APP_VERSION=1.0.0 app
    docker run --rm -p 8080:3000 devsecops-demo-api:local

The runtime image installs production dependencies only and runs as the unprivileged node account. It contains no credentials. Tests use Node's built-in test runner with coverage reporting; no minimum coverage threshold is enforced.
