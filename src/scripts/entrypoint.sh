#!/bin/bash
set -e

CRAC_FILES_DIR=`eval echo ${CRAC_FILES_DIR}`
mkdir -p $CRAC_FILES_DIR

if [ -z "$(ls -A $CRAC_FILES_DIR)" ]; then
  echo 128 > /proc/sys/kernel/ns_last_pid; java -XX:CRaCCheckpointTo="$CRAC_FILES_DIR" -Dspring.context.checkpoint=onRefresh -jar /opt/app/app.jar&
  wait # Spring exists after writing the checkpoint - wait
  touch /opt/mnt/checkpoint_complete # signal to host that checkpoint has been written
  sleep infinity # keep container alive so it can be committed
else
  java -XX:CRaCRestoreFrom=$CRAC_FILES_DIR &
  PID=$!
  trap "kill $PID" SIGINT SIGTERM
  wait $PID
fi
