#!/bin/bash

function print_usage(){
  echo "Usage: start [-options]"
  echo " where options include:"
  echo "     -help                          Documentation"
  echo "     -http_port <port>              Http port"
  echo "     -server_IP <server_IP>         The IP of Ambari-Server"
  echo "     -cluster_name <name>           The name of cluster"
  echo "     -skip_hadoop                   Do not install hadoop"
}

#cd `dirname $0`
http_port=81
server_IP=""
cluster_name=""
csv="csv"
skip_hadoop=""

while [[ $# -gt 0 ]]; do
    case "$1" in
           -help)  print_usage; exit 0 ;;
       -http_port) http_port=$2 && shift 2;;
       -server_IP) server_IP=$2 && shift 2;;
       -cluster_name) cluster_name=$2 && shift 2;;
       -csv) csv=1 && shift ;;
       -skip_hadoop) skip_hadoop=1 && shift ;;
    esac
done

#根据../conf/hosts.csv文件内判断journalnode_stat的值
journalnode_stat=""
if [ "$skip_hadoop" = "" ]; then
  journalnode_hosts=`cat ../conf/hosts.csv | grep SUGO_JOURNALNODE | cut -d \, -f 3-`
  arr=(${journalnode_hosts//,/ })
  journalnode_num=0
  for i in ${arr[@]}
  do
      journalnode_num=$[$journalnode_num + 1]
  done

  i=0
  while true;do
    if [ $i -lt $journalnode_num ];then
      journalnode_stat=$journalnode_stat"STARTED"
  	i=$[$i+1]
  	continue
    else
      break
    fi
  done
fi

baseurl=http://$server_IP:$http_port/sugo_yum

#pw=`cat ../ambari-server/ip.txt | sed -n "1p" |awk '{print $2}'`

if [ "$http_port" -eq 0 ]
  then
    echo "-http_port is required!"
    exit 1
fi

if [ "$server_IP" = "" ]
  then
    echo "-server_IP is required!"
    exit 1
fi

if [ "$cluster_name" = "" ]
  then
    echo "-cluster_name is required!"
    exit 1
fi

#修改host文件并根据ascii码对hostname进行排序
cd ../ambari-server

rm -rf host1 host2
rm -rf ../ambari-agent/host

cat host | while read line;
do
ip1=`echo $line|awk '{print $1}'`
hn1=`echo $line|awk '{print $2}'`
echo "$hn1 $ip1" >> host1
done

sort host1 >> host2

cat host2 | while read line;
do
hn2=`echo $line|awk '{print $1}' | tr '[A-Z]' '[a-z]'`
ip2=`echo $line|awk '{print $2}'`
echo "$ip2 $hn2" >> ../ambari-agent/host
done

rm -rf host1 host2

cd -
#sort ../ambari-server/host > ../ambari-agent/host

cluster_host1=`cat ../ambari-agent/host | sed -n "1p" |awk '{print $2}'`
cluster_host2=`cat ../ambari-agent/host | sed -n "2p" |awk '{print $2}'`
cluster_host3=`cat ../ambari-agent/host | sed -n "3p" |awk '{print $2}'`

if [ "$skip_hadoop" = "" ]; then
  sed -i "s/host1/${cluster_host1}/g" host_until_hdfs.json
  sed -i "s/host2/${cluster_host2}/g" host_until_hdfs.json
  sed -i "s/host3/${cluster_host3}/g" host_until_hdfs.json

  sed -i "s/host1/${cluster_host1}/g" host_after_hdfs.json
  sed -i "s/host2/${cluster_host2}/g" host_after_hdfs.json
  sed -i "s/host3/${cluster_host3}/g" host_after_hdfs.json

  #sed -i "s/test1.sugo.vm/${cluster_host1}/g" host_hdfs.json
  #sed -i "s/test2.sugo.vm/${cluster_host2}/g" host_hdfs.json
  #sed -i "s/test3.sugo.vm/${cluster_host3}/g" host_hdfs.json
else
  sed -i "s/host1/${cluster_host1}/g" hosts_csv.json
  sed -i "s/host2/${cluster_host2}/g" hosts_csv.json
  sed -i "s/host3/${cluster_host3}/g" hosts_csv.json
fi

#获取namenode及astro所在主机并替换astro和druid的配置项
cd ../service/
rm -rf namenode_astro_host.txt
if [ "$skip_hadoop" = "" ]; then
  python get_host.py host_until_hdfs.json namenode_astro_host.txt
  python get_host.py host_after_hdfs.json namenode_astro_host.txt
  namenode1=`cat namenode_astro_host.txt | grep "namenode1" | awk '{print $2}'`
  namenode2=`cat namenode_astro_host.txt | grep "namenode2" | awk '{print $2}'`
else
  python get_host.py hosts_csv.json namenode_astro_host.txt
fi

astro_host=`cat namenode_astro_host.txt | grep "astro_host" | awk '{print $2}'`
redis_host=`cat namenode_astro_host.txt | grep "redis_host" | awk '{print $2}'`
postgres_host=`cat namenode_astro_host.txt | grep "postgres_host" | awk '{print $2}'`
gateway_host=`cat namenode_astro_host.txt | grep "gateway_host" | awk '{print $2}'`

#alter parameters
rm -rf changed_configuration
cp -r changed_configurations changed_configuration
sed -i "s/test1.sugo.vm/${astro_host}/g" changed_configuration/astro-site.xml
sed -i "s/test2.sugo.vm/${gateway_host}/g" changed_configuration/astro-site.xml
sed -i "s/test3.sugo.vm/${postgres_host}/g" changed_configuration/astro-site.xml
sed -i "s/test4.sugo.vm/${redis_host}/g" changed_configuration/astro-site.xml
sed -i "s/test1.sugo.vm/${postgres_host}/g" changed_configuration/common.runtime.xml
cd -

#判断httpd服务是否已启动
http_service=`netstat -ntlp | grep $http_port | grep httpd`
if [ "$http_service" = "" ];then
    echo "service http not running, please start it first!"
    exit
fi

#判断ambari-server是否已经启动，如果没有，则等待启动完成
ambari=`netstat -ntlp | grep 8080`
printf "waiting for ambari-server to start"
x=0
while [ "$ambari" = "" ]
do
  ambari=`netstat -ntlp | grep 8080`
  if [ "$ambari" = "" ];then
    sleep 1
    x=$[$x+1]
    if [ $x -lt 60 ];then
        printf "."
        continue
    else
        echo -e "\n==========Timeout==========\nThe installation of Ambari-server failed, please check the configurations and run start.sh again!"
        exit 1
    fi
  else
    break
  fi
done
echo ""

#创建集群、更新基础url，安装注册ambari-agent
./install_cluster.sh $http_port $server_IP $cluster_name
sleep 5

#重启ambari
#ambari-server restart


if [ "$skip_hadoop" = "" ]; then
  #安装hdfs及之前的服务
  python install_service.py $server_IP $cluster_name host_until_hdfs.json
  sleep 15

    #判断hdfs是否已经安装，如果没有则等待安装完成
    hdfs_dir="/opt/apps/hadoop_sugo"
    printf "waiting for hdfs to be installed"
    y=0
    while [ ! -d "$hdfs_dir" ]
    do
      hdfs_dir="/opt/apps/hadoop_sugo"
      if [ ! -d "$hdfs_dir" ];then
        sleep 3
        y=$[$y+1]
        if [ $y -lt 180 ];then
            printf "."
            continue
        else
            echo -e "\n==========Timeout==========\nThe installation of HDFS failed, please check the configurations and run start.sh again!"
            exit 1
        fi
      else
        break
      fi
    done
    echo ""

   #启动hdfs及之前的服务
   echo "starting service postgres, redis, zookeeper and hdfs~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
   python start_service.py $server_IP $cluster_name host_until_hdfs.json
   sleep 10

    #判断所有journalnode是否都已经启动
    printf "waiting for journalnode to start"
    z=0
    while true;do
    curl -u admin:admin -H "X-Requested-By: ambari" -X GET "http://$server_IP:8080/api/v1/clusters/$cluster_name/components/?ServiceComponentInfo/category=SLAVE&fields=ServiceComponentInfo/service_name,host_components/HostRoles/display_name,host_components/HostRoles/host_name,host_components/HostRoles/state,host_components/HostRoles/maintenance_state,host_components/HostRoles/stale_configs,host_components/HostRoles/ha_state,host_components/HostRoles/desired_admin_state,&minimal_response=true&_=1499937079425" > slave.json
    python slave.py slave.json > slave.txt
    state=`sed ':a;N;$!ba;s/\n//g' slave.txt`
      if [ "$state" = "$journalnode_stat" ];then
        # hdfs初始化
        echo "formating hdfs~~~"
        #创建pg数据库并格式化hdfs
        if [ "$csv" = "" ];then
            ./hdfsformat.sh -server_IP $server_IP -cluster_name $cluster_name
        else
            ./hdfsformat.sh -server_IP $server_IP -cluster_name $cluster_name -csv
        fi
        break
      else
        sleep 5
        z=$[$z+1]
        if [ $z -lt 60 ];then
          printf "."
          continue
        else
          echo -e "\n==========Timeout==========\nThe start of HDFS failed, you can start HDFS on http://"'$ambari_server'":8080, or check the configurations and run start.sh again!"
          exit 1
        fi
      fi
    done
    echo "hdfs format finished~~~~~~~~~~~~~~~~~~~~~~"

  #安装hdfs之后的所有服务
  python install_service.py $server_IP $cluster_name host_after_hdfs.json
  sleep 10

  #判断astro是否已经安装完成
  /usr/bin/expect <<-EOF
  set timeout 100000
  spawn ssh $astro_host
                  expect "*]#*"
            send "wget $baseurl/deploy_scripts/centos6/service/pg_db_astro.sh\n"
                  expect "*]#*"
            send "chmod 755 pg_db_astro.sh\n"
                  expect "*]#*"
            send "./pg_db_astro.sh\n"
                  expect "*]#*"
            send "rm -rf pg_db_astro.sh\n"
                  expect "*]#*"
EOF

  #start剩余所有服务
  python start_service.py $server_IP $cluster_name host_after_hdfs.json
else
  python install_service.py $server_IP $cluster_name hosts_csv.json
  sleep 15

  #判断astro是否已经安装完成
  /usr/bin/expect <<-EOF
  set timeout 100000
  spawn ssh $astro_host
                  expect "*]#*"
            send "wget $baseurl/deploy_scripts/centos6/service/pg_db_astro.sh\n"
                  expect "*]#*"
            send "chmod 755 pg_db_astro.sh\n"
                  expect "*]#*"
            send "./pg_db_astro.sh\n"
                  expect "*]#*"
            send "rm -rf pg_db_astro.sh\n"
                  expect "*]#*"
EOF

  #启动服务
  python start_service.py $server_IP $cluster_name hosts_csv.json
fi