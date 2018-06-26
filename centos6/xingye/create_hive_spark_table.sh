#!/bin/bash

ambari_user=$1
postgres_host=$2

if [[ `hostname` == $postgres_host ]];then
    /opt/apps/postgres_sugo/bin/psql -p 15432 -U $ambari_user -d postgres -c "CREATE DATABASE hive WITH OWNER = ambari ENCODING = UTF8;"
    /opt/apps/postgres_sugo/bin/psql -p 15432 -U $ambari_user -d postgres -c "select datname from pg_database"
    su - $ambari_user <<-EOF
    hdfs dfs -mkdir -p /tmp/spark-events
    hdfs dfs -chmod 777 /tmp/spark-events
    hdfs dfs -mkdir -p /user/spark
    hdfs dfs -chmod 777 /user/spark
    hdfs dfs -chown -R spark:spark /user/spark
    hdfs dfs -mkdir -p /tmp/hive
    hdfs dfs -chmod 777 /tmp/hive
    hdfs dfs -chown -R hive:hadoop /tmp/hive
    hdfs dfs -mkdir -p /user/hive
    hdfs dfs -chmod 777 /user/hive
    hdfs dfs -chown -R hive:hadoop /user/hive
EOF

else 
    ssh -tt root@$postgres_host <<-EOF
    su - $ambari_user
        /opt/apps/postgres_sugo/bin/psql -p 15432 -U $ambari_user -d postgres -c "CREATE DATABASE hive WITH OWNER = ambari ENCODING = UTF8;"
        /opt/apps/postgres_sugo/bin/psql -p 15432 -U $ambari_user -d postgres -c "select datname from pg_database"
        hdfs dfs -mkdir -p /tmp/spark-events
        hdfs dfs -chmod 777 /tmp/spark-events
        hdfs dfs -mkdir -p /user/spark
        hdfs dfs -chmod 777 /user/spark
        hdfs dfs -chown -R spark:spark /user/spark
        hdfs dfs -mkdir -p /tmp/hive
        hdfs dfs -chmod 777 /tmp/hive
        hdfs dfs -chown -R hive:hadoop /tmp/hive
        hdfs dfs -mkdir -p /user/hive
        hdfs dfs -chmod 777 /user/hive
        hdfs dfs -chown -R hive:hadoop /user/hive
        exit
    exit
EOF
fi