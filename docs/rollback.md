# Deployment and rollback

## State model

deployment/scripts/deploy.sh takes an immutable image reference and optional health URL. It reads the prior healthy image from deployment/.last-known-good, pulls and starts the new image, and polls /health. It records the new reference only after health returns success. If startup or health fails, it tries to redeploy the previous reference and checks health again. The process exits nonzero for a failed release even when restoration succeeds, so Jenkins reports a failed deployment attempt.

The state file is machine-local and ignored by Git. Keep prior images available in the registry until the replacement has passed validation and the desired retention period. If rollback cannot become healthy, inspect container logs and act manually.

## Local operation

With Docker running and the local registry from jenkins/compose.yml started, the Jenkins pipeline performs image build, scan, push, and deployment. The service listens only on 127.0.0.1:18080.

The script-based test scripts/test-rollback.sh replaces Docker and curl with stubs, creates an isolated temp state file, forces the health endpoint to fail, and asserts that the prior image was selected. It validates control flow only; it does not create or restart a container.

## Limits

This is a single-service Compose update and may interrupt requests while replacing the container. It is not a zero-downtime strategy. Rollback assumes the previous image exists and application/database changes remain backward compatible. A real deployment should rehearse recovery with persistent state, observe logs/metrics, and define an explicit data migration strategy.
