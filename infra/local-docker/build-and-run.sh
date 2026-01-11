#!/bin/bash
# build-and-run.sh - 建置並執行 CRaC warm-up Docker 環境
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Building adapter-mng JAR ==="
cd "$PROJECT_ROOT"
./gradlew :adapter-mng:assemble -x test

echo "=== Copying JAR to warm-up-docker ==="
cp "$PROJECT_ROOT/adapter-mng/build/libs/adapter-mng-0.0.1-SNAPSHOT.jar" "$SCRIPT_DIR/crac"
cp "$PROJECT_ROOT/adapter-mng/build/libs/adapter-mng-0.0.1-SNAPSHOT.jar" "$SCRIPT_DIR/restore"
cd "$SCRIPT_DIR"



echo "=== Building checkpoint image ==="
cd "${SCRIPT_DIR}/crac"
docker compose build
docker compose up

echo "=== Checkpoint creation completed ==="
echo "=== You can now run: docker compose up restore ==="
cd "${SCRIPT_DIR}/restore"
docker compose build
docker compose up
