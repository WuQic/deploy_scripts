#!/bin/bash

#创建druid、sugo_astro/pio库
printf "~~~~~~~~~~~~~~~~~~~~~~~~~start to create databases~~~~~~~~~~~~~~~~~~~~~~~~~~~"
while true; do
postgres_path="/opt/apps/postgres_sugo"
if [ ! -d "$postgres_path" ]; then
    sleep 3
    z=$[$z+1]
    if [ $z -lt 60 ];then
      printf "."
      continue
    else
      echo -e "\n==========Timeout==========\nThe install of postgresql failed"
      exit 1
    fi
else
    postgres_pidfile="/data1/postgres/data/postmaster.pid"
    if [ ! -f "$postgres_pid" ]; then
        su - postgres -c "/opt/apps/postgres_sugo/bin/pg_ctl -D /data1/postgres/data -l /data1/postgres/log/postgres.log start"
        sleep 3
        cd /opt/apps/postgres_sugo
        bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE druid WITH OWNER = postgres ENCODING = UTF8;"
        bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE sugo_astro WITH OWNER = postgres ENCODING = UTF8;"
        bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE pio WITH OWNER = postgres ENCODING = UTF8;"
        cd -
        sleep 3
        su - postgres -c "/opt/apps/postgres_sugo/bin/pg_ctl -D /data1/postgres/data -l /data1/postgres/log/postgres.log stop"
    else
        cd /opt/apps/postgres_sugo
        bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE druid WITH OWNER = postgres ENCODING = UTF8;"
        bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE sugo_astro WITH OWNER = postgres ENCODING = UTF8;"
        bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE pio WITH OWNER = postgres ENCODING = UTF8;"
        cd -
    fi
    break
fi
done


#判断astro是否已经安装完成
  printf "waiting for astro to be installed"
  x=0
  astro_dir="/opt/apps/astro_sugo"
  while [ ! -d "$astro_dir" ]
  do
    astro_dir="/opt/apps/astro_sugo"
    if [ ! -d "$astro_dir" ];then
      sleep 3
      x=$[$x+1]
      if [ $x -lt 180 ];then
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