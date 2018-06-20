#!/bin/bash

pg_user="ambari"

#创建druid、sugo_astro/pio库
postgres_path="/opt/apps/postgres_sugo"
if [ -d "$postgres_path" ];
then
postgres_pid=`head -1 /data1/postgres/data/postmaster.pid`
    if [ "$postgres_pid" = "" ];
        then
        su - postgres -c "/opt/apps/postgres_sugo/bin/pg_ctl -D /data1/postgres/data -l /data1/postgres/log/postgres.log start"
        sleep 3
    fi

cd /opt/apps/postgres_sugo
bin/psql -p 15432 -U $pg_user -d postgres -c "CREATE DATABASE druid WITH OWNER = $pg_user ENCODING = UTF8;"
bin/psql -p 15432 -U $pg_user -d postgres -c "CREATE DATABASE sugo_astro WITH OWNER = $pg_user ENCODING = UTF8;"
bin/psql -p 15432 -U $pg_user -d postgres -c "CREATE DATABASE pio WITH OWNER = $pg_user ENCODING = UTF8;"
bin/psql -p 15432 -U $pg_user -d postgres -c "CREATE DATABASE uindex WITH OWNER = $pg_user ENCODING = UTF8;"
cd -
fi

#判断astro是否已经安装完成
  printf "waiting for astro to be installed"
  x=0
  astro_dir="/opt/apps/astro_sugo"
  while [ ! -d "$astro_dir" ]
  do
    astro_dir="/opt/apps/astro_sugo"
    if [ ! -d "$astro_dir" ];then
      sleep 2
      x=$[$x+1]
      if [ $x -lt 60 ];then
        printf "."
        continue
      else
        echo -e "\n==========Timeout==========\nThe installation of ASTRO failed, you can check it on http://$ambari_server:8080, or cancel the start.sh and check the configurations, run start.sh again!"
        continue
      fi
    else
      echo "astro has been installed!~~~"
      break
    fi
  done
echo ""
