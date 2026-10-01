#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAKE="$(mktemp -d)"
STATE="$FAKE/state"
LOG="$FAKE/docker.log"
COUNT="$FAKE/curl-count"
trap 'rm -rf "$FAKE"' EXIT
cat > "$FAKE/docker" <<'SH'
#!/usr/bin/env bash
printf 'IMAGE_REF=%s %s\n' "$IMAGE_REF" "$*" >> "$FAKE_DOCKER_LOG"
exit 0
SH
cat > "$FAKE/curl" <<'SH'
#!/usr/bin/env bash
n=0
[[ -f "$FAKE_CURL_COUNT" ]] && n="$(cat "$FAKE_CURL_COUNT")"
n=$((n + 1))
printf '%s\n' "$n" > "$FAKE_CURL_COUNT"
[[ "$n" -eq 1 ]] && exit 22
exit 0
SH
chmod +x "$FAKE/docker" "$FAKE/curl"
printf '%s\n' 'registry.local/app:good' > "$STATE"
export PATH="$FAKE:$PATH" FAKE_DOCKER_LOG="$LOG" FAKE_CURL_COUNT="$COUNT"
export HEALTH_ATTEMPTS=1 HEALTH_INTERVAL_SECONDS=0 STATE_FILE="$STATE"
set +e
OUTPUT="$("$ROOT/deployment/scripts/deploy.sh" registry.local/app:bad http://fake/health 2>&1)"
RC=$?
set -e
[[ "$RC" -eq 1 ]]
printf '%s\n' "$OUTPUT" | grep -q 'Rollback health validation passed: registry.local/app:good'
grep -q 'registry.local/app:good' "$LOG"
printf '%s\n' 'PASS: failed candidate health triggered restoration and successful health validation of the prior image; Docker was stubbed.'
