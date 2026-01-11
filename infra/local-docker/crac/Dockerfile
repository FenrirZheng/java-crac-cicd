# Dockerfile.checkpoint - 建立 CRaC checkpoint 的映像檔
# 使用 Azul Zulu JDK 25 with CRaC support
FROM azul/zulu-openjdk:25-jdk-crac

# 安裝 curl
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 複製 JAR 檔案 (app.jar : 名子當作常數 表示將要啟動的Jar)
COPY adapter-mng-0.0.1-SNAPSHOT.jar app.jar

# 複製並設定 checkpoint 腳本
COPY checkpoint.sh /checkpoint.sh
RUN chmod +x /checkpoint.sh

# 建立 checkpoint 目錄
RUN mkdir -p /checkpoint

# 設定必要的 capabilities (CRaC 需要)
# 注意：執行時需要 --privileged 或適當的 capabilities

CMD ["/checkpoint.sh"]
