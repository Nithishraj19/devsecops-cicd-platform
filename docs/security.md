# Security design and local checks

## Scanner choices

- **Gitleaks:** scans Git history and current repository content for known credential patterns. Output is redacted. Detection is a blocking gate; rotate/revoke any real leaked credential and remove it from history with the repository owner’s approved process.
- **ESLint plus eslint-plugin-security:** inexpensive static checks integrated with the app toolchain. They are a project SAST-style check, not a comprehensive security audit.
- **npm audit:** scans the lockfile against npm advisories. The pipeline fails at HIGH and CRITICAL. Network and advisory freshness affect results.
- **Trivy:** image scanner; gate fails on HIGH/CRITICAL and ignores unfixed findings, while filesystem config also enables misconfiguration and secret scanners. These are selected project thresholds, not industry-wide standards.
- **SonarQube:** optional local analysis. It is not required by Jenkins and no analysis result is claimed.

## Safe Gitleaks failure demonstration

Do not place a genuine token in this repository. When Gitleaks is installed, create a disposable dummy-pattern file outside the Git checkout, scan it, and delete it:

    tmpdir=$(mktemp -d)
    printf 'DEMO_SECRET_%s\n' '0123456789ABCDEF0123456789ABCDEF' > "$tmpdir/demo.txt"
    gitleaks dir --redact --config security/gitleaks/.gitleaks.toml "$tmpdir"
    rm -rf "$tmpdir"

The DEMO_SECRET marker is a nonfunctional project-specific canary configured only to make this failure path reproducible. The scan is expected to find it and return nonzero. Never use a real account's key. The normal pipeline uses a Git scan, which includes committed history; this isolated demo exercises directory scanning only.

## Credential handling

- Keep .env files, tokens, private keys, and registry credentials out of Git. The root ignore file excludes local env files; .env.example contains only harmless defaults.
- Store optional registry, Sonar, Slack, and SMTP credentials in Jenkins Credentials. Bind them only in the relevant stage and avoid printing their values.
- Do not pass secrets as Docker build args or bake them into image layers. Use runtime secret mechanisms for a real deployment.
- Local Jenkins mounts the Docker socket. Treat its jobs as trusted code with broad local host control; never attach untrusted PR jobs to it.
- Use short-lived, least-privilege credentials and rotate exposed credentials immediately.

## Artifact integrity and governance

The pipeline tags images with build number and commit prefix rather than latest. The local registry is unauthenticated and is for learning only. A production workflow should use authenticated TLS registry access, provenance/signing, retention rules, isolated build agents, protected branches, reviewed Jenkinsfile changes, and auditable credential access. GitHub branch protection and webhook configuration are recommendations, not settings claimed as configured here.

## Safe gate exercises

- Unit test: from app, run node --test test/failing-test.example.cjs; this is expected to fail. The failing fixture is excluded by npm test's default discovery suffix.
- Secret scan: use the temporary sample above, then remove it.
- Dependency: npm audit checks current lockfile advisories; avoid intentionally adding known vulnerable packages to the regular dependency tree.
- Image scan: build a tagged image and run Trivy. Any image meeting configured HIGH/CRITICAL policy fails.
- Health failure: run scripts/test-rollback.sh to exercise rollback branch using stub commands. It makes no Docker changes.
