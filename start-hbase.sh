#!/bin/bash
if [[ "$ROLE" == "h-master" ]]; then
  if ! hdfs dfs -test -d /hbase; then
    hdfs dfs -mkdir -p /hbase
    hdfs dfs -chown hadoop:hadoop /hbase
  fi
  $HBASE_HOME/bin/hbase master start

elif [[ "$ROLE" == "region-server" ]]; then 
  hdfs --daemon start datanode
  yarn --daemon start nodemanager
  $HBASE_HOME/bin/hbase-daemon.sh start regionserver
fi
tail -f /dev/null