# CRaC Deploy

這是一個用於部署 Java 應用程式的 CI/CD 專案，使用 CRaC (Coordinated Restore at Checkpoint) 技術實現快速啟動。

## 專案結構

```
crac-deploy/
├── deploy_from_local/       # 從本地部署到遠端伺服器
├── infra/
│   ├── local-docker/        # 本地 Docker 開發環境
│   ├── uat-docker-compose/  # UAT 環境 Docker Compose 配置
│   └── warm-up-shell/       # 本地 CRaC warm-up 腳本（非 Docker）
```

## 資料夾說明

### deploy_from_local/

從開發者本地機器部署應用程式到遠端伺服器的腳本。

| 檔案           | 說明                        |
|--------------|---------------------------|
| `deploy.sh`  | Linux/macOS 用的部署腳本        |
| `deploy.ps1` | Windows PowerShell 用的部署腳本 |

功能：

- 複製 JAR 檔案到遠端伺服器
- 執行遠端部署腳本
- 發送 Google Chat 通知（部署開始、成功、失敗）

---

### infra/local-docker/

本地 Docker 開發環境，用於在本地測試 CRaC checkpoint/restore 流程。

| 檔案/資料夾               | 說明                                 |
|----------------------|------------------------------------|
| `crac/`              | CRaC checkpoint 建立的 Docker 配置      |
| `crac/Dockerfile`    | 建立 checkpoint 的映像檔                 |
| `crac/checkpoint.sh` | checkpoint 建立腳本                    |
| `restore/`           | CRaC restore 執行的 Docker 配置         |
| `restore/Dockerfile` | 從 checkpoint 還原的映像檔                |
| `build-and-run.sh`   | 一鍵建置 JAR 並執行 checkpoint/restore 流程 |
| `rsync.sh`           | 同步本地 Docker 配置到遠端伺服器               |

---

### infra/uat-docker-compose/

UAT 環境的 Docker Compose 部署配置。

| 檔案/資料夾                    | 說明                       |
|---------------------------|--------------------------|
| `deploy/`                 | 部署用的 Docker 配置（會被複製到遠端）  |
| `deploy/crac/`            | UAT 環境的 checkpoint 配置    |
| `deploy/restore/`         | UAT 環境的 restore 配置       |
| `deploy/build-and-run.sh` | UAT 環境的建置執行腳本            |
| `new-deploy.sh`           | 新版部署腳本（建立時間戳記備份、自動清理舊備份） |
| `rsync.sh`                | 同步部署配置到遠端 UAT 伺服器        |

---

### infra/warm-up-shell/

本地 CRaC warm-up 腳本（不使用 Docker，直接在本地執行）。

| 檔案               | 說明                            |
|------------------|-------------------------------|
| `warm-up.sh`     | 執行應用程式 warm-up 並建立 checkpoint |
| `check-point.sh` | 透過 jcmd 觸發 checkpoint         |

用途：本地開發測試 CRaC 功能，不需要 Docker 環境。

---

## 部署流程

1. **本地開發者執行** `deploy_from_local/deploy.sh`
2. JAR 檔案透過 rsync 傳輸到遠端伺服器
3. 遠端伺服器執行 `new-deploy.sh`
4. 建立時間戳記備份資料夾
5. 執行 `build-and-run.sh` 進行 checkpoint 建立與服務啟動
6. 自動清理 5 天前的舊備份

## 技術棧

- **Java Runtime**: Azul Zulu JDK 25 with CRaC support
- **容器化**: Docker / Docker Compose
- **CRaC Engine**: Warp mode
