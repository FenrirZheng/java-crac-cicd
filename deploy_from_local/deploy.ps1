#!/usr/bin/env pwsh

############################
# 使用前需要配置
############################
# 1. 確保已安裝 OpenSSH client
# 2. 設定 SSH key 認證到遠端伺服器
# 3. 設定環境變數 GOOGLE_CHAT_WEBHOOK（可選）

param(
    [string]$RemoteHost = "CMS-Sit-02",
    [string]$RemoteUser = "root",
    [string]$RemoteDeployDir = "/root/deploy-mng/deploy"
)

$ErrorActionPreference = "Stop"

# Google Chat Webhook 設定
$GOOGLE_CHAT_WEBHOOK = $env:GOOGLE_CHAT_WEBHOOK
if (-not $GOOGLE_CHAT_WEBHOOK) {
    $GOOGLE_CHAT_WEBHOOK = "YOUR_GOOGLE_WEB_HOOK"
}

############################
# Google Chat Webhook 通知
############################

function Send-Notification {
    param([string]$Message)

    if ($GOOGLE_CHAT_WEBHOOK) {
        try {
            $body = @{ text = $Message } | ConvertTo-Json -Compress
            Invoke-RestMethod -Uri $GOOGLE_CHAT_WEBHOOK -Method Post -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -ErrorAction SilentlyContinue | Out-Null
        } catch {
            # 忽略通知錯誤
        }
    }
}

function Send-CardNotification {
    param(
        [string]$Title,
        [string]$Status,
        [string]$IconUrl,
        [string]$Details
    )

    if ($GOOGLE_CHAT_WEBHOOK) {
        try {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $card = @{
                cards = @(
                    @{
                        header = @{
                            title = $Title
                            subtitle = "Casino Management System"
                            imageUrl = $IconUrl
                        }
                        sections = @(
                            @{
                                widgets = @(
                                    @{
                                        keyValue = @{
                                            topLabel = "狀態"
                                            content = $Status
                                        }
                                    },
                                    @{
                                        keyValue = @{
                                            topLabel = "環境"
                                            content = $RemoteHost
                                        }
                                    },
                                    @{
                                        keyValue = @{
                                            topLabel = "時間"
                                            content = $timestamp
                                        }
                                    },
                                    @{
                                        textParagraph = @{
                                            text = $Details
                                        }
                                    }
                                )
                            }
                        )
                    }
                )
            }

            $body = $card | ConvertTo-Json -Depth 10 -Compress

            # 關鍵修改：1. 指定 charset=utf-8  2. 將 $body 轉為 UTF8 Bytes
            $utf8Body = [System.Text.Encoding]::UTF8.GetBytes($body)

            Invoke-RestMethod -Uri $GOOGLE_CHAT_WEBHOOK `
                              -Method Post `
                              -ContentType "application/json; charset=utf-8" `
                              -Body $utf8Body `
                              -ErrorAction SilentlyContinue | Out-Null
        } catch {
            # 忽略通知錯誤
        }
    }
}

############################
# 主程序
############################

function Main-Process {
    # 切換到專案根目錄
    $ScriptDir = Split-Path -Parent $MyInvocation.ScriptName
    $BuildRoot = Split-Path -Parent $ScriptDir
    Set-Location $BuildRoot

    Write-Host "Build Root: $BuildRoot"

    # 獲取 Git 資訊
    $GitUser = git config user.name 2>$null
    if (-not $GitUser) {
        Write-Host "ERROR: 無法取得 Git 使用者名稱" -ForegroundColor Red
        Write-Host "請先設定 Git 使用者名稱："
        Write-Host "  git config --global user.name `"你的名字`""
        exit 1
    }

    $GitRevision = git rev-parse --short HEAD 2>$null
    if (-not $GitRevision) { $GitRevision = "unknown" }

    $GitBranch = git branch --show-current 2>$null
    if (-not $GitBranch) { $GitBranch = "unknown" }

    Write-Host "Git User: $GitUser"
    Write-Host "Git Revision: $GitRevision"
    Write-Host "Git Branch: $GitBranch"

    # 設定路徑
    $DockerBuildRoot = Join-Path $BuildRoot ".build_cache"
    $AppJar = "adapter-mng-0.0.1-SNAPSHOT.jar"
    $SourceJar = Join-Path $BuildRoot "adapter-mng/build/libs/$AppJar"

    # 清理並建立 build cache
    if (Test-Path $DockerBuildRoot) {
        Remove-Item -Recurse -Force $DockerBuildRoot
    }
    New-Item -ItemType Directory -Path $DockerBuildRoot -Force | Out-Null

    # 檢查 JAR 檔案是否存在
    if (-not (Test-Path $SourceJar)) {
        Write-Host "ERROR: JAR 檔案不存在: $SourceJar" -ForegroundColor Red
        Write-Host "請先執行 ./gradlew :adapter-mng:build"
        exit 1
    }

    # 複製 JAR 到 build cache
    Copy-Item $SourceJar $DockerBuildRoot

    Write-Host ""
    Write-Host "=== Deploying to $RemoteHost ===" -ForegroundColor Cyan

    # 發送部署開始通知
    $details = "正在部署 <b>$AppJar</b> 到 <b>$RemoteHost</b><br><b>部署者:</b> $GitUser<br><b>Revision:</b> $GitRevision<br><b>Branch:</b> $GitBranch"
    Send-CardNotification `
        -Title "🚀 CMS 部署開始" `
        -Status "進行中" `
        -IconUrl "https://fonts.gstatic.com/s/i/short-term/release/googlesymbols/rocket_launch/default/48px.svg" `
        -Details $details

    # Step 1: 複製 JAR 到遠端伺服器
    Write-Host "Copying $AppJar to ${RemoteHost}:${RemoteDeployDir}/" -ForegroundColor Yellow

    $LocalJarPath = Join-Path $DockerBuildRoot $AppJar
    $RemotePath = "${RemoteUser}@${RemoteHost}:${RemoteDeployDir}/"

    try {
        # 使用 scp 複製檔案
        & scp $LocalJarPath $RemotePath
        if ($LASTEXITCODE -ne 0) {
            throw "SCP failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Host "ERROR: Failed to copy JAR file to remote server" -ForegroundColor Red
        Write-Host $_.Exception.Message

        # 使用 <br> 換行，並加入粗體標籤
        $errorDetails = "❌ <b>錯誤：JAR 檔案複製失敗</b><br><b>部署者：</b>$GitUser<br><b>Revision：</b>$GitRevision<br><b>Branch：</b>$GitBranch"
        Send-CardNotification `
            -Title "❌ CMS 部署失敗" `
            -Status "失敗" `
            -IconUrl "https://fonts.gstatic.com/s/i/short-term/release/googlesymbols/error/default/48px.svg" `
            -Details $errorDetails
        exit 1
    }

    # Step 2: 在遠端伺服器執行部署腳本
    Write-Host "Executing new-deploy.sh on ${RemoteHost}..." -ForegroundColor Yellow

    $RemoteScript = "sh -x /root/deploy-mng/new-deploy.sh"

    try {
        & ssh "${RemoteUser}@${RemoteHost}" $RemoteScript
        if ($LASTEXITCODE -ne 0) {
            throw "SSH command failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Host "ERROR: Failed to execute new-deploy.sh on remote server" -ForegroundColor Red
        Write-Host $_.Exception.Message

        $errorDetails = "⚠️ <b>錯誤：遠端部署腳本執行失敗</b><br><b>執行路徑：</b>/root/deploy-mng/new-deploy.sh<br><b>部署者：</b>$GitUser<br><b>Revision：</b>$GitRevision<br><b>Branch：</b>$GitBranch"
        Send-CardNotification `
            -Title "❌ CMS 部署失敗" `
            -Status "失敗" `
            -IconUrl "https://fonts.gstatic.com/s/i/short-term/release/googlesymbols/error/default/48px.svg" `
            -Details $errorDetails
        exit 1
    }

    # 清理 build cache
    if (Test-Path $DockerBuildRoot) {
        Remove-Item -Recurse -Force $DockerBuildRoot
    }

    Write-Host ""
    Write-Host "=== Deployment completed successfully ===" -ForegroundColor Green

    # 發送部署成功通知
    $successDetails = "部署已成功完成<br><b>👤 部署者:</b> $GitUser<br><b>🔖 Revision:</b> $GitRevision<br><b>🌿 Branch:</b> $GitBranch"
    Send-CardNotification `
        -Title "✅ CMS 部署成功" `
        -Status "完成" `
        -IconUrl "https://fonts.gstatic.com/s/i/short-term/release/googlesymbols/check_circle/default/48px.svg" `
        -Details $successDetails
}

# 執行主程序
Main-Process
