#!/bin/bash

function print_usage(){
  echo "Usage: start [-options]"
  echo " where options include:"
  echo "     -help                          Documentation"
  echo "     -server_IP <server_IP>         (required)The IP of Ambari-Server"
  echo "     -cluster_name <name>           (required)The name of cluster"
  echo "     -csv                           Choose the hosts that the component installed on, or take the defaults without the parameter"
}

#cd `dirname $0`
server_IP=""
cluster_name=""
csv=""

while [[ $# -gt 0 ]]; do
    case "$1" in
           -help)  print_usage; exit 0 ;;
       -server_IP) server_IP=$2 && shift 2;;
       -cluster_name) cluster_name=$2 && shift 2;;
       -csv) csv=1 && shift ;;
    esac
done

if [ "$csv" = "" ];then
    namenode1=`cat ../ambari-agent/host | sed -n "1p" |awk '{print $2}'`
    namenode2=`cat ../ambari-agent/host | sed -n "2p" |awk '{print $2}'`
else
    namenode_hosts=`cat ../conf/hosts.csv | grep SUGO_NAMENODE | cut -d \, -f 3-`
    arr=(${namenode_hosts//,/ })
    namenode1=${arr[0]}
    namenode2=${arr[1]}
fi

if [ ! -f ip.txt ]; then
  passwd_file=host
else
  passwd_file=ip.txt
fi

pw1=`cat ../ambari-server/$passwd_file | grep $namenode1 |awk '{print $1}'`
pw2=`cat ../ambari-server/$passwd_file | grep $namenode2 |awk '{print $1}'`

#配置namenode的hdfs用户之间的免密码登录
./passwdless.sh $namenode1 $namenode2 hdfs hdfs

#格式化namenode
#1.格式化zkfc并启动namenode1节点的zkfc
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $namenode1
        expect {
        "*yes/no*" { send "yes\n"
        expect "*assword:" { send "$pw1\n" } }
        "*assword:" { send "$pw1\n" }
        "*]#*" { send "\n"}
        "*]#*"
        }
            expect "*]#*"
        send "su - hdfs\n"
            expect "*]\$*"
        send "hdfs zkfc -formatZK -nonInteractive\n"
            expect "*]\$*"
        send "/opt/apps/hadoop_sugo/sbin/hadoop-daemon.sh --script /opt/apps/hadoop_sugo/bin/hdfs start zkfc\n"
            expect "*]\$*"
EOF

#2.启动namenode2节点的zkfc
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $namenode2
        expect {
        "*yes/no*" { send "yes\n"
        expect "*assword:" { send "$pw2\n" } }
        "*assword:" { send "$pw2\n" }
        "*]#*" { send "\n"}
                "*]#*" 
        }
            expect "*]#*"
        send "su - hdfs\n"
            expect "*]\$*"
        send "/opt/apps/hadoop_sugo/sbin/hadoop-daemon.sh --script /opt/apps/hadoop_sugo/bin/hdfs start zkfc\n"
            expect "*]\$*"
EOF

#3.格式化namenode1并启动namenode1
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $namenode1
        expect {
        "*yes/no*" { send "yes\n"
        expect "*assword:" { send "$pw1\n" } }
        "*assword:" { send "$pw1\n" }
        "*]#*" { send "\n"}
                "*]#*" 
        }
            expect "*]#*"
        send "su - hdfs\n"
            expect "*]\$*"
        send "hdfs namenode -format\n"
            expect "*~]\$*"
        send "cd /opt/apps/hadoop_sugo; ./sbin/hadoop-daemon.sh start namenode\n"
            expect "*]\$*"
EOF



#4.namenode2同步格式化后的namenode1的数据，并启动hdfs所有组件
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $namenode2
        expect {
        "*yes/no*" { send "yes\n"
        expect "*assword:" { send "$pw2\n" } }
        "*assword:" { send "$pw2\n" }
        "*]#*" { send "\n"}
                "*]#*" 
        }
            expect "*]#*"
        send "su - hdfs\n"
            expect "*]\$*"
        send "hdfs namenode -bootstrapStandby\n"
            expect "*~]\$*"
        send "/opt/apps/hadoop_sugo/sbin/hadoop-daemon.sh start namenode\n"
            expect "*]\$*"
EOF

echo `pwd`
#启动hdfs所有组件
#python start_service.py $server_IP $cluster_name host_hdfs.json

#/usr/bin/expect <<-EOF
#set timeout 100000
#spawn ssh $namenode1
#        expect {
#        "*yes/no*" { send "yes\n"
#        expect "*assword:" { send "$pw1\n" } }
#        "*assword:" { send "$pw1\n" }
#        "*]#*" { send "\n"}
#                "*]#*" 
#        }
#            expect "*]#*"
#        send "/opt/apps/hadoop_sugo/sbin/start-dfs.sh\n"
#            expect "*]#**"
#EOF

