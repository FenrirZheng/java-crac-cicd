# Dockerfile.restore - 從 CRaC checkpoint 還原並執行的映像檔
# 使用 Azul Zulu JRE 25 with CRaC support (較小的映像)
FROM azul/zulu-openjdk:25-jdk-crac

WORKDIR /app

# 複製 JAR 檔案
COPY adapter-mng-0.0.1-SNAPSHOT.jar app.jar

# 從 checkpoint 容器複製 checkpoint 資料
#COPY checkpoint /checkpoint

EXPOSE 18080

ENTRYPOINT ["java", "-XX:CRaCEngine=warp", \
            "-Xlog:crac=info", \
            "-XX:CRaCRestoreFrom=/checkpoint"]
