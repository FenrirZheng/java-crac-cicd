#!/bin/bash
# build-and-run.sh - 建置並執行 CRaC warm-up Docker 環境
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


echo "=== Copying JAR to warm-up-docker ==="
cp "$SCRIPT_DIR/adapter-mng-0.0.1-SNAPSHOT.jar" "$SCRIPT_DIR/crac"
cp "$SCRIPT_DIR/adapter-mng-0.0.1-SNAPSHOT.jar" "$SCRIPT_DIR/restore"
cd "$SCRIPT_DIR"


echo "=== Building checkpoint image ==="
CHECKPOINT_COMPOSE_FILE="${SCRIPT_DIR}/crac/docker-compose.yml"
docker compose -f "${CHECKPOINT_COMPOSE_FILE}" build
docker compose -f "${CHECKPOINT_COMPOSE_FILE}" up


echo "=== Checkpoint creation completed ==="
echo "=== You can now run: docker compose up restore ==="
#The container_name directive should explicitly set the name to mng-web without any project prefix.
# If the issue persists after removing the old container
MNG_WEB_COMPOSE_FILE="${SCRIPT_DIR}/restore/docker-compose.yml"
docker compose -f "${MNG_WEB_COMPOSE_FILE}" build


docker compose -f "${CHECKPOINT_COMPOSE_FILE}" down
docker compose -f "${MNG_WEB_COMPOSE_FILE}" up -d
sleep 1
docker compose -f  "${MNG_WEB_COMPOSE_FILE}"  ps

