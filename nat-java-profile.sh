#!/bin/sh

set -ex

#PID=15048
#CTN_ID=ab3ef93ec56d
PID=10667
CTN_ID=1eadcccf58b6
JAVA_HOME=`docker exec ${CTN_ID} java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' |cut -d'=' -f2|sed -e 's/\/jre//' | xargs`
#JAVA_BIN=`docker exec ${CTN_ID} ps -ef | grep jav[a] | awk '{print $4}'`
JAVA_BIN=java
#JAVA_PID=`docker exec ${CTN_ID} ps -ef | grep ${JAVA_BIN} | awk '{ print $1 }'`
JAVA_PID=1
JAVA_UID=root
JAVA_GID=root
#JAVA_UID=`docker exec ${CTN_ID} ps -e -o pid,user,group,comm | grep ${JAVA_BIN} | awk '{ print $2 }'`
#JAVA_GID=`docker exec ${CTN_ID} ps -e -o pid,user,group,comm | grep ${JAVA_BIN} | awk '{ print $3 }'`

echo ">>>>Vinuth>>>"
echo $JAVA_HOME
echo $JAVA_BIN
echo $JAVA_PID
echo $JAVA_UID
echo $JAVA_GID
# We copy libperfmap.so and attach-main.jar to target container
docker cp /home/admin/Vinuth/perf-map-agent-master/out ${CTN_ID}:/tmp/perf-map-agent

# Command to populate a /tmp/perf-PID.map file with the symbols
docker exec --user "${JAVA_UID}":"${JAVA_GID}" "${CTN_ID}" sh -c "cd /tmp/perf-map-agent && java -XX:+StartAttachListener -cp /tmp/perf-map-agent/attach-main.jar:${JAVA_HOME}/lib/tools.jar net.virtualvoid.perf.AttachOnce ${JAVA_PID}"

# Copy back to our perf container
docker cp ${CTN_ID}:/tmp/perf-${JAVA_PID}.map /tmp/perf-${PID}.map

# We profile 15 seconds
/usr/share/bcc/tools/profile -adf -p $PID 300 > $PID.profile

# Draw flamegraph
/home/admin/Vinuth/FlameGraph-master/flamegraph.pl < $PID.profile --colors java --hash > $PID.svg
