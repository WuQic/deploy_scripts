#!/bin/bash

baseurl=$1
conf_dir=$2
init_url=$baseurl/deploy_scripts/centos6/ambari-server

#在ambari-server节点配置ssh
rm -rf /root/.ssh
./ssh.sh $baseurl

#将/root/.ssh/id_rsa.pub放到yum源目录下的SG/Centos6/1.0/:
rm -rf ../../../SG/centos6/1.0/id_rsa.pub
cp /root/.ssh/id_rsa.pub ../../../SG/centos6/1.0/

cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

cat $conf_dir |while read line;
do
hn=`echo $line|awk '{print $1}'`
pw=`echo $line|awk '{print $2}'`
local_hn=`hostname`

if [ "$hn" == "$local_hn" ];then
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $hn
        expect {
                "*yes/no*" { send "yes\n";exp_continue}
                "*assword*" { send "${pw}\n";exp_continue}
                "*]#*" { send "exit\n"}
        }
EOF
fi

if [ "$hn" != "$local_hn" ];then
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $hn
        expect {
		"*yes/no*" { send "yes\n";exp_continue}
		"*assword*" { send "${pw}\n"}
	}
        expect "*]#*"
                send "wget $init_url/ssh.sh\n"
        expect "*]#*" 
                send "chmod 755 ssh.sh\n"
        expect "*]#*" 
                send "./ssh.sh $baseurl\n"
        expect "*]#*" 
                send "rm -rf ssh.sh*\n"
        expect "*]#*"
                send "exit\n"
EOF
fi
done
