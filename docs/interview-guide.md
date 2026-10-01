# DevSecOps interview guide

## What is DevSecOps, and how does it differ from DevOps?
DevSecOps integrates security checks and ownership into the delivery lifecycle. It extends DevOps feedback and automation with security policy, threat-aware review, and remediation. Security remains a shared engineering responsibility rather than a final approval queue.

## What is shift-left security?
It moves useful checks nearer to code authoring and pull requests so issues are found while changes are small. It does not remove runtime, infrastructure, or operational security controls.

## Why use SAST?
Static analysis inspects source without running the application. It can identify suspicious patterns early. Results need context because scanners can produce false positives and cannot understand every business rule. Here ESLint plus its security rules is a lightweight gate, not an enterprise SAST claim.

## SAST versus SCA?
SAST inspects first-party source patterns. Software Composition Analysis inventories third-party packages and matches versions to known advisories and licenses. This project uses ESLint rules and npm audit respectively.

## Why Gitleaks?
It searches source and Git history for credential-like patterns before release. If a genuine credential is found, block the build, revoke it, then assess exposure and history remediation; deleting the visible line alone does not invalidate the credential.

## How does npm audit fit?
It evaluates lockfile dependencies against npm advisory data. A finding should be assessed for reachability, exploitability, upgrade compatibility, and transitive impact. The sample fails on HIGH and above; the threshold is project policy.

## What does Trivy scan?
It scans container images and can inspect filesystems, configuration and secrets. The image gate here blocks HIGH/CRITICAL findings and ignores unfixed issues. A scan is a snapshot of the image and feed at scan time.

## Why SonarQube?
It can centralize code analysis and quality gates. It is optional here because a local service consumes resources and needs scanner/token configuration. The repository does not claim a Sonar result.

## What is a security gate?
A blocking pipeline condition that prevents an artifact moving forward when policy is not met. This pipeline blocks on tests, lint, npm audit, Gitleaks, and Trivy. Exceptions should be reviewed, time-limited, and auditable rather than hidden.

## How should Jenkins credentials be managed?
Store values in the Jenkins credential store, bind only for a specific stage, mask output, scope permissions, rotate them, and avoid interpolation into logs or image layers. A credential ID can be referenced by pipeline code; its secret value must never be committed.

## What makes a Jenkins pipeline secure?
Protect Jenkins and agents, restrict job permissions, review Jenkinsfile changes, isolate untrusted PRs from privileged agents, scope credentials, pin or verify tooling, keep logs/artifacts, and make gates fail clearly. The included local Jenkins socket mount is powerful and intentionally for a trusted disposable environment only.

## Why a non-root container?
It reduces the privileges available to an attacker who compromises the process. It is one layer alongside minimal images, patched dependencies, restricted capabilities, and runtime controls.

## Why immutable image tags?
A versioned commit/build tag points deployment to a specific artifact and supports traceability and rollback. Rebuilding an identically named mutable tag can change what that tag means.

## What is artifact promotion?
The same scanned image is advanced between environments rather than rebuilt for each one. This sample pushes and deploys the same local registry reference on main; it does not implement multiple environments or image signing.

## How does rollback work?
The deploy script remembers the last health-validated image, deploys a candidate, polls /health, and attempts to restore the prior image if the check fails. Rollback itself must be health-validated. The current stub test checks command selection, not a running container; Compose replacement can interrupt traffic.

## Health check versus readiness?
Health reports whether the process is responding according to an endpoint. A production readiness check should also account for dependencies and whether an instance can safely receive traffic. Here /health indicates process lifecycle status and is intentionally simple.

## CI versus CD?
Continuous integration validates changes frequently. Continuous delivery keeps a validated artifact ready to release; continuous deployment automatically releases it. This sample runs a main-branch local deployment after configured gates, but does not represent production continuous deployment.

## How should PR security checks work?
Run tests and non-secret-bearing scanners against PR code in isolated, least-privileged workers. Do not expose deployment credentials or a privileged Docker socket to untrusted fork PRs. Protect main with review and required checks as repository settings; this project does not claim these settings are configured.

## What is supply-chain security?
It covers the provenance and integrity of source, dependencies, build tools, artifacts, and delivery identities. This sample has lockfile-based installation, scanners and versioned tags, but not signatures, attestations, SBOM publication, or hardened isolated build infrastructure.

## How do you handle false positives?
Reproduce and assess the context, document evidence, involve the right owner, and apply a narrow time-bound exception if policy allows. Keep the original finding visible and track remediation.

## What if a dependency is vulnerable?
Identify direct/transitive origin, advisory severity, exploitability and reachable path. Upgrade to a supported fix, test compatibility, and rebuild/rescan. If no fix exists, use compensating controls and an explicit reviewed exception.

## What about an emergency release?
Use a documented expedited review path with minimum required tests and risk acceptance by an authorized owner. Do not silently disable secret or critical security gates; record what was waived and schedule follow-up.

## How do you balance security and delivery speed?
Automate fast, relevant checks early; run heavier analysis at the right cadence; make findings actionable; and reserve exceptions for evidence-based decisions. A slow/noisy pipeline encourages bypasses, while invisible risk creates incidents.

## What does this project not claim?
No AWS deployment, production release, zero downtime, Sonar pass, or Docker run is claimed unless the corresponding environment and validation were actually performed.
