# Pipeline operation

## Required tools on the Jenkins node

The local Jenkins image includes Node.js/npm, Docker CLI and Compose plugin, Gitleaks, and Trivy. The pipeline expects a trusted Jenkins agent, Git checkout, an available Docker daemon, registry at localhost:5000, and host.docker.internal resolving to the host from Jenkins (Docker Desktop on macOS supports this).

The local controller mounts the host Docker socket for a compact learning setup. That gives jobs broad Docker host privilege. Keep the UI loopback-only and do not run untrusted pull-request branches on it. For shared or production Jenkins, use isolated ephemeral agents and a secured remote build service instead.

## Stage behavior

1. Checkout and version: SCM checkout, capture commit, create build-commit image reference.
2. Install and unit tests: npm ci and node --test.
3. SAST/lint: ESLint configured with security plugin.
4. Dependency SCA: npm audit fails on HIGH or greater.
5. Secret scan: Gitleaks git scans tracked history and working tree with redaction.
6. Build image: Docker builds with version build argument.
7. Image report: Trivy reports UNKNOWN/LOW/MEDIUM findings without blocking.\n8. Image gate: Trivy fails on HIGH/CRITICAL and ignores unfixed issues.
9. On main only: push approved image to localhost:5000 and deploy that exact reference.
10. Deployment script validates /health. Failed health invokes previous image restoration.
11. Jenkins console logs pipeline status. Optional notification integrations need separately configured plugins and Jenkins credentials.

The first failing stage halts later stages. Jenkins post actions report status, but they do not override scanner exits.

## Jenkins startup

    docker compose -f jenkins/compose.yml build
    docker compose -f jenkins/compose.yml up -d

Create a Jenkins Pipeline or Multibranch Pipeline that loads the root Jenkinsfile. Configure SCM credentials through Jenkins when required. Branch-specific push/deploy uses Declarative branch condition and expects a Multibranch job with branch name metadata. Run from a trusted main branch after the other checks succeed.

## Optional SonarQube

If you choose local SonarQube, run its official Community Build container separately (not part of the default Compose stack), create a local project token, and install/use SonarScanner on an agent. Use security/sonar/sonar-project.properties and pass the token through Jenkins credentials/environment. The configured qualitygate.wait option makes the scanner wait for the server result. This optional scan is not a Jenkins gate in the delivered Jenkinsfile and has not been represented as executed.

The local service can consume substantial memory. Stop it when not in use. SonarQube with its bundled evaluation database is suitable for local evaluation only; configure a supported external database for a durable shared service.

## Registry and credentials

The local registry is intended for a single machine and has no auth. The Jenkinsfile pushes only after all local scans pass. For Docker Hub or a private registry, add a Jenkins credential and an explicit login stage that uses stdin/password binding; never put credentials in Jenkinsfile, Compose, shell history, or an image. External registry integration is optional and not required to reproduce local code checks.
