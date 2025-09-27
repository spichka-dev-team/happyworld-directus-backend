#!/bin/sh
# Wait until Directus is reachable then exec directus-sync with passed arguments
set -e
: ${DIRECTUS_URL_SYNC:=http://directus:8055}
: ${WAIT_TIMEOUT:=60}
: ${WAIT_INTERVAL:=2}

echo "Waiting for Directus at ${DIRECTUS_URL_SYNC}/server/health (timeout ${WAIT_TIMEOUT}s)"

start=$(date +%s)
while true; do
  if wget -qO- "${DIRECTUS_URL_SYNC}/server/health" >/dev/null 2>&1; then
    echo "Directus is reachable"
    break
  fi
  now=$(date +%s)
  elapsed=$((now - start))
  if [ "$elapsed" -ge "$WAIT_TIMEOUT" ]; then
    echo "Timeout waiting for Directus after ${WAIT_TIMEOUT}s"
    exit 1
  fi
  echo "Still waiting for Directus..."
  sleep ${WAIT_INTERVAL}
done

# exec the original command (directus-sync ...) with all args
exec directus-sync "$@"
