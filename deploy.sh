#!/bin/bash

# Backend Deployment Script (prod)
# - Pull git latest changes
# - Rebuild and restart docker containers
# - Perform health checks after wait start/sleep

# Performs exactly these steps:
# 1) git pull
# 2) docker compose -f ./docker-compose.prod.yml down
# 3) docker compose -f ./docker-compose.prod.yml build --no-cache
# 4) docker compose -f ./docker-compose.prod.yml up -d
# 5) wait until Directus starts and check health
# 6) log the logs of docker compose - (docker compose -f ./docker-compose.prod.yml logs)

# NOTES
#- docker compose build --no-cache (flag --no-cache is disabled now!)
# TODO
#- if your Dockerfile/Docker Image is pushed to the Container Registry, consider to change the code to pull with :prod flag the image and do not rebuild it everytime


set -euo pipefail
IFS=$'\n\t'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# TODO: add the printing and other info's with colors!

# Always run from repo root
cd "$(dirname "$0")"

# Config (override via env if needed)
COMPOSE_FILE=${COMPOSE_FILE:-"./docker-compose.prod.yml"}
DIRECTUS_PORT=${DIRECTUS_PORT:-8060}    # host port mapped to 8055
HEALTH_TIMEOUT=${HEALTH_TIMEOUT:-120}   # seconds
HEALTH_INTERVAL=${HEALTH_INTERVAL:-5}   # seconds
LOG_TAIL=${LOG_TAIL:-200}               # number of log lines to print

# Degubing the CI/CD workflows/deploy-ssh.yml
echo "--- [DEBUG] ---"

echo "[INFO] whoami - display username of the current user"
whoami

# Main Commands
echo "--- [MAIN COMMANDS] ---"

echo "[1/6] git pull"
git pull

echo "[2/6] docker compose down"
docker compose -f "$COMPOSE_FILE" down

#echo "[3/6] docker compose build --no-cache"
#docker compose -f "$COMPOSE_FILE" build --no-cache

echo "[3/6] docker compose build"
docker compose -f "$COMPOSE_FILE" build

echo "[4/6] docker compose up -d"
docker compose -f "$COMPOSE_FILE" up -d

echo "[5/6] waiting for Directus to be healthy..."
HEALTH_URL="http://localhost:${DIRECTUS_PORT}/server/health"
deadline=$(( $(date +%s) + HEALTH_TIMEOUT ))
ok=false
while [ $(date +%s) -lt $deadline ]; do
	if curl -fsS "$HEALTH_URL" >/dev/null 2>&1 || wget -qO- "$HEALTH_URL" >/dev/null 2>&1; then
		ok=true
		break
	fi
	sleep "$HEALTH_INTERVAL"
done

echo "[6/6] docker compose logs (prod)"
if [ "$ok" = true ]; then
	echo "✅ Healthy: http://localhost:${DIRECTUS_PORT}"
	# Print recent logs for context then exit
	docker compose -f "$COMPOSE_FILE" logs --no-color --tail "$LOG_TAIL"
	exit 0
else
	echo "❌ Health check failed after ${HEALTH_TIMEOUT}s at $HEALTH_URL"
	# Print logs to help diagnose failures, then exit with error
	docker compose -f "$COMPOSE_FILE" logs --no-color --tail "$LOG_TAIL" || true
	exit 1
fi
