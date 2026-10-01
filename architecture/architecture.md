# Architecture notes

## Purpose and boundaries

This is a **local-first DevSecOps hands-on portfolio project**. GitHub hosts source; Jenkins runs the pipeline; Docker builds and runs the artifact; Gitleaks, ESLint security rules, npm audit, and Trivy enforce source, dependency, secret, and image checks. No cloud resource or production deployment is part of the default design.

## Flow

1. A developer pushes a branch or opens a pull request. GitHub starts a Jenkins SCM job; webhook configuration is an external repository setting and is not claimed as preconfigured.
2. Jenkins checks out the commit and derives a unique image tag from build number and commit prefix.
3. It installs from package-lock.json, runs Node tests, ESLint security rules, npm audit, and Gitleaks. A nonzero check stops the pipeline.
4. Docker builds the app image. Trivy evaluates the local image. The report retains lower-severity findings; the selected gate blocks HIGH or CRITICAL vulnerabilities and ignores unfixed findings.
5. On main, Jenkins pushes the scanned versioned artifact into the local registry. Compose deploys that same reference.
6. The deployment script polls /health. A failure causes a redeploy of the last recorded healthy image and a second health validation.
7. Jenkins console output reports completion or failure. Slack/email hooks remain optional integrations.

## Trust and artifact boundaries

- GitHub checkout is untrusted input until all checks pass. Do not run untrusted PR code on a privileged self-hosted Jenkins agent.
- Jenkins stores job configuration and optional credentials in its data volume/credential store, never in Git or image layers.
- The provided local Jenkins Compose service mounts /var/run/docker.sock; this gives broad privilege over the local Docker engine. Keep Jenkins loopback-only and use it as a disposable trusted learning setup.
- The local registry is loopback-bound and has no authentication/TLS configuration; do not treat it as a production registry.
- Image tags include a unique build/commit suffix. No latest promotion or cross-environment signing is implemented.
- The demo app has no secret configuration and runs as a non-root container user.

## Security gates and limitations

Unit tests, lint, dependency audit, Gitleaks, and Trivy image scanning are blocking checks in Jenkinsfile. npm audit uses HIGH as its minimum failing severity; Trivy uses HIGH and CRITICAL and ignores unfixed findings. These thresholds are explicit project policy choices. ESLint security rules are lightweight source analysis, not equivalent to a mature commercial SAST engine. SonarQube is optional and separately configured; it is not a required pipeline result.

## Local deployment and rollback

The Compose runtime publishes the app only on 127.0.0.1:18080. The deployment script reads/writes deployment/.last-known-good (ignored by Git), deploys a versioned registry image, polls health, and attempts rollback on failure. Rollback requires the old image to remain available in the local registry. The included stub-based check validates script branching, not Docker behavior or zero-downtime semantics.
