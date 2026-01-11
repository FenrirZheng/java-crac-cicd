#!/usr/bin/env zsh
JAVA=/home/fenrir/.sdkman/candidates/java/25.0.1.crac-zulu/bin/java
WORK_DIR=/home/fenrir/code/casino-management-system
JAVA_HOME=/home/fenrir/.sdkman/candidates/java/25.0.1.crac-zulu/

export JAVA_HOME
export JAVA
export WORK_DIR
#rm -rf bin

ls -la "${JAVA_HOME}/lib/criu"


APP_JAR="${WORK_DIR}/adapter-mng/build/libs/adapter-mng-0.0.1-SNAPSHOT.jar"
export APP_JAR

# 取得bin下 jar的路徑
cd ./bin || exit 1
APP_JAR=$(find . -maxdepth 1 -name "*.jar" -type f -printf "%f\n" | head -1)

# 觸發checkpoint!
jcmd "${APP_JAR}" JDK.checkpoint
