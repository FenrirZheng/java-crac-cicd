#!/usr/bin/env zsh
JAVA=/home/fenrir/.sdkman/candidates/java/25.0.1.crac-zulu/bin/java
WORK_DIR=/home/fenrir/code/casino-management-system
JAVA_HOME=/home/fenrir/.sdkman/candidates/java/25.0.1.crac-zulu/

export JAVA_HOME
export JAVA
export WORK_DIR
rm -rf bin

ls -la "${JAVA_HOME}/lib/criu"


APP_JAR="${WORK_DIR}/adapter-mng/build/libs/adapter-mng-0.0.1-SNAPSHOT.jar"
export APP_JAR
mkdir -p bin
cp "${APP_JAR}" ./bin/
# 取得bin下 jar的路徑
cd ./bin || exit 1
APP_JAR=$(find . -maxdepth 1 -name "*.jar" -type f -printf "%f\n" | head -1)

#"${JAVA}" -XX:ArchiveClassesAtExit=app-cds.jsa \
#    -Dspring.context.exit=onRefresh \
#    -jar "${APP_JAR}"

# 體驗用的參數...
#-Dspring.context.checkpoint=onRefresh

"${JAVA}" -XX:CRaCEngine=warp  \
    -Djdk.crac.collect-fd-stacktraces=true \
    -XX:CRaCCheckpointTo=checkpoint_folder \
    -XX:CPUFeatures=generic \
    -jar "${APP_JAR}"

# 觸發checkpoint!
#jcmd "${APP_JAR}" JDK.checkpoint

sleep 1
#-jar -XX:SharedArchiveFile=app-cds.jsa

# 多餘
# -jar "${APP_JAR}"
"${JAVA}" -XX:CRaCEngine=warp  -Xlog:crac=trace  -XX:CRaCRestoreFrom=checkpoint_folder
