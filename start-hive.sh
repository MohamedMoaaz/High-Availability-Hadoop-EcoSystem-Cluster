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
  mkdir /app
  sudo service cron start
  echo export PATH=/usr/local/hive/bin:/usr/local/hadoop/bin:/usr/bin:/bin >> /app/hive_cron.sh
  echo "beeline -u jdbc:hive2://localhost:10000 -n hive -p hive -f /app/transformation.sql >> /app/hive_cron.log 2>&1" >> /app/hive_cron.sh
  chmod +x /app/hive_cron.sh 
  echo "0 2 * * * /app/hive_cron.sh" | crontab -
fi
tail -f /dev/null