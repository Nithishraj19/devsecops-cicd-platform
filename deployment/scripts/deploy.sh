#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="$ROOT/deployment/docker-compose.yml"
STATE_FILE="${STATE_FILE:-$ROOT/deployment/.last-known-good}"
IMAGE_REF="${1:?Usage: deploy.sh IMAGE_REF [HEALTH_URL]}"
APP_HOST_PORT="${APP_HOST_PORT:-18080}"
HEALTH_URL="${2:-${HEALTH_URL:-http://127.0.0.1:${APP_HOST_PORT}/health}}"
COMPOSE=(docker compose -f "$COMPOSE_FILE")
PREVIOUS=""
[[ -f "$STATE_FILE" ]] && PREVIOUS="$(cat "$STATE_FILE")"
export IMAGE_REF
export APP_VERSION="${IMAGE_REF##*:}"
echo "Deploying immutable image reference: $IMAGE_REF"
if ! "${COMPOSE[@]}" pull app || ! "${COMPOSE[@]}" up -d --no-deps app; then
  echo "Deployment command failed." >&2
  if [[ -n "$PREVIOUS" ]]; then IMAGE_REF="$PREVIOUS"; APP_VERSION="${PREVIOUS##*:}"; export IMAGE_REF APP_VERSION; "${COMPOSE[@]}" up -d --no-deps app; fi
  exit 1
fi
for attempt in $(seq 1 "${HEALTH_ATTEMPTS:-15}"); do
  if curl --fail --silent --show-error "$HEALTH_URL" >/dev/null 2>&1; then
    printf '%s\n' "$IMAGE_REF" > "$STATE_FILE"
    echo "Health validation passed; current release is $IMAGE_REF"
    exit 0
  fi
  sleep "${HEALTH_INTERVAL_SECONDS:-2}"
done
echo "Health validation failed for $IMAGE_REF; reverting to prior known-good image." >&2
if [[ -n "$PREVIOUS" ]]; then
  IMAGE_REF="$PREVIOUS"; APP_VERSION="${PREVIOUS##*:}"; export IMAGE_REF APP_VERSION
  if "${COMPOSE[@]}" pull app && "${COMPOSE[@]}" up -d --no-deps app; then
    for attempt in $(seq 1 "${HEALTH_ATTEMPTS:-15}"); do
      if curl --fail --silent "$HEALTH_URL" >/dev/null 2>&1; then echo "Rollback health validation passed: $PREVIOUS" >&2; exit 1; fi
      sleep "${HEALTH_INTERVAL_SECONDS:-2}"
    done
  fi
  echo "Rollback attempted but its health check did not pass; operator action required." >&2
else
  echo "No previous known-good release is recorded; failed container remains for diagnosis." >&2
fi
exit 1
