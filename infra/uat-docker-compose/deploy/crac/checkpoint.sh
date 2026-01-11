#!/bin/bash
# checkpoint.sh - 建立 CRaC checkpoint 的腳本
set -e

echo "=== Starting application for checkpoint creation ==="

# 啟動應用程式並準備 checkpoint
java -XX:CRaCEngine=warp \
     -Djdk.crac.collect-fd-stacktraces=true \
     -XX:CPUFeatures=generic \
     -XX:CRaCCheckpointTo=/checkpoint \
     -jar /app/app.jar &

PID=$!
echo "Application started with PID: $PID"

# 等待應用程式啟動完成 (檢查 health endpoint)
echo "=== Waiting for application to be ready ==="
MAX_WAIT=20
WAIT_COUNT=0

until curl -sf http://127.0.0.1:18080/adaptor01/mng/hello/health > /dev/null 2>&1; do
    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
        echo "ERROR: Application failed to start within ${MAX_WAIT} seconds"
        kill $PID 2>/dev/null || true
        exit 1
    fi
    echo "Waiting for application... ($WAIT_COUNT/${MAX_WAIT}s)"
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done
echo "=== Application is ready! ==="

# 可選：執行 warm-up 請求 (根據需要調整 endpoints)
echo "=== Executing warm-up requests ==="
# curl -sf http://localhost:18080/api/warmup || true

# 等待一小段時間讓 JIT 編譯完成
sleep 3

# 觸發 checkpoint
echo "=== Triggering checkpoint ==="
jcmd $PID JDK.checkpoint

# 等待 checkpoint 完成
wait $PID || true

echo "=== Checkpoint created successfully ==="
ls -la /checkpoint/


