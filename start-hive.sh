#!/bin/bash
if [[ "$ROLE" == "metastore" ]]; then
  hdfs dfs -mkdir -p /user/hive/warehouse
  hdfs dfs -mkdir -p /tmp/hive
  hdfs dfs -mkdir -p /tez
  hdfs dfs -put -f $TEZ_HOME/share/* /tez/
  hdfs dfs -chmod g+w /user/hive/warehouse
  hdfs dfs -chmod g+w /tmp/hive
  hdfs dfs -chmod g+w /tez
  if [ ! -f /usr/local/hive/metastore_schema_initialized ]; then
      schematool -dbType postgres -initSchema
      touch /usr/local/hive/metastore_schema_initialized
  fi
  hive --service metastore &
fi

if [[ "$ROLE" == "server2" ]]; then
  hive --service hiveserver2 &
fi
tail -f /dev/null
