#!/usr/bin/env bash

############################
# 使用前需要配置
############################
#➜  casino-management-system git:(main) ✗ docker login http://reg.alliance.com:10081
#Username: admin
#Password:
#
#WARNING! Your credentials are stored unencrypted in '/home/fenrir/.docker/config.json'.
#Configure a credential helper to remove this warning. See
#https://docs.docker.com/go/credential-store/
#
#Login Succeeded
export  GOOGLE_CHAT_WEBHOOK="YOUR_GOOGLE_WEB_HOOK"
############################
# Google Chat Webhook 通知
############################
# 設定環境變數: export GOOGLE_CHAT_WEBHOOK="https://chat.googleapis.com/v1/spaces/XXXXX/messages?key=YYYY&token=ZZZZ"
GOOGLE_CHAT_WEBHOOK="${GOOGLE_CHAT_WEBHOOK:-}"

# 發送 Google Chat 通知
send_notification() {
    local message="$1"
    if [[ -n "${GOOGLE_CHAT_WEBHOOK}" ]]; then
        curl -s -X POST "${GOOGLE_CHAT_WEBHOOK}" \
            -H "Content-Type: application/json" \
            -d "{\"text\": \"${message}\"}" > /dev/null 2>&1 || true
    fi
}

# 發送 Card 格式通知（更豐富的訊息）
send_card_notification() {
    local title="$1"
    local status="$2"
    local icon="$3"
    local details="$4"
    if [[ "${ENABLE_GOOGLE_NOTIFY}" != "true" ]]; then
      return
    fi
    if [[ -n "${GOOGLE_CHAT_WEBHOOK}" ]]; then
        curl -s -X POST "${GOOGLE_CHAT_WEBHOOK}" \
            -H "Content-Type: application/json" \
            -d '{
                "cards": [{
                    "header": {
                        "title": "'"${title}"'",
                        "subtitle": "Casino Management System",
                        "imageUrl": "'"${icon}"'"
                    },
                    "sections": [{
                        "widgets": [
                            {
                                "keyValue": {
                                    "topLabel": "狀態",
                                    "content": "'"${status}"'"
                                }
                            },
                            {
                                "keyValue": {
                                    "topLabel": "環境",
                                    "content": "'"${REMOTE_HOST:-unknown}"'"
                                }
                             },
                            {
                                "keyValue": {
                                    "topLabel": "時間",
                                    "content": "'"$(date '+%Y-%m-%d %H:%M:%S')"'"
                                }
                            },
                            {
                                "textParagraph": {
                                    "text": "'"${details}"'"
                                }
                            }
                        ]
                    }]
                }]
            }' > /dev/null 2>&1 || true
    fi
}

main_process(){
  cd ../
BUILD_ROOT="$(pwd)"
export BUILD_ROOT

# 獲取 Git 資訊
GIT_USER=$(git config user.name 2>/dev/null || echo "")
if [[ -z "${GIT_USER}" ]]; then
    echo "ERROR: 無法取得 Git 使用者名稱"
    echo "請先設定 Git 使用者名稱："
    echo "  git config --global user.name \"你的名字\""
    exit 1
fi
GIT_REVISION=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
export GIT_USER
export GIT_REVISION
export GIT_BRANCH
DOCKER_BUILD_ROOT="${BUILD_ROOT}/.build_cache"
APP_JAR=adapter-mng-0.0.1-SNAPSHOT.jar
export DOCKER_BUILD_ROOT
export APP_JAR
export REGISTRY=reg.alliance.com
export TAG=latest
export REPOSITORY='cms/casino-mng'
export REGISTRY
rm -rf "${BUILD_ROOT}/.build_cache"
mkdir -p "${BUILD_ROOT}/.build_cache"
cp "${BUILD_ROOT}/adapter-mng/build/libs/${APP_JAR}" "${DOCKER_BUILD_ROOT}/"

# Remote deployment configuration
REMOTE_HOST="CMS-Sit-02"
REMOTE_USER="root"
REMOTE_DEPLOY_DIR="/root/deploy-mng/deploy"
ENABLE_GOOGLE_NOTIFY=false
echo "=== Deploying to ${REMOTE_HOST} ==="

# 發送部署開始通知
send_card_notification \
    "🚀 CMS 部署開始" \
    "進行中" \
    "https://fonts.gstatic.com/s/i/short-term/release/googlesymbols/rocket_launch/default/48px.svg" \
    "正在部署 ${APP_JAR} 到 ${REMOTE_HOST}\\n👤 部署者: ${GIT_USER}\\n🔖 Revision: ${GIT_REVISION}\\n🌿 Branch: ${GIT_BRANCH}"

# Step 1: Copy JAR file to remote server
echo "Copying ${APP_JAR} to ${REMOTE_HOST}:${REMOTE_DEPLOY_DIR}/"
if ! rsync -avz "${DOCKER_BUILD_ROOT}/${APP_JAR}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DEPLOY_DIR}/"; then
    echo "ERROR: Failed to copy JAR file to remote server"
    send_card_notification \
        "❌ CMS 部署失敗" \
        "失敗" \
        "https://fonts.gstatic.com/s/i/short-term/release/googlesymbols/error/default/48px.svg" \
        "錯誤: JAR 檔案複製失敗\\n👤 部署者: ${GIT_USER}\\n🔖 Revision: ${GIT_REVISION}\\n🌿 Branch: ${GIT_BRANCH}"
    exit 1
fi

# Step 2: Execute deploy.sh on remote server
echo "Executing deploy.sh on ${REMOTE_HOST}..."
if ! ssh "${REMOTE_USER}@${REMOTE_HOST}" bash <<'REMOTE_SCRIPT'
    set -e
    sh -x /root/deploy-mng/new-deploy.sh
REMOTE_SCRIPT
then
    echo "ERROR: Failed to execute deploy.sh on remote server"
    send_card_notification \
        "❌ CMS 部署失敗" \
        "失敗" \
        "https://fonts.gstatic.com/s/i/short-term/release/googlesymbols/error/default/48px.svg" \
        "錯誤: 遠端部署腳本執行失敗\\n👤 部署者: ${GIT_USER}\\n🔖 Revision: ${GIT_REVISION}\\n🌿 Branch: ${GIT_BRANCH}"
    exit 1
fi

rm -rf "${BUILD_ROOT}/.build_cache"
echo "=== Deployment completed successfully ==="

# 發送部署成功通知
send_card_notification \
    "✅ CMS 部署成功" \
    "完成" \
    "https://fonts.gstatic.com/s/i/short-term/release/googlesymbols/check_circle/default/48px.svg" \
    "部署已成功完成\\n👤 部署者: ${GIT_USER}\\n🔖 Revision: ${GIT_REVISION}\\n🌿 Branch: ${GIT_BRANCH}"
}

# MAIN

main_process
