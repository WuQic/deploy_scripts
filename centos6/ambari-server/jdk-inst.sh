#!/bin/bash

baseurl=$1
params_file=$2
init_url=$baseurl/deploy_scripts/centos6/ambari-server


./jdk.sh $baseurl

cat $params_file | while read line;
do
pw=`echo $line|awk '{print $1}'`
hn=`echo $line|awk '{print $2}'`
local_hn=`hostname`

if [ "$hn" != "$local_hn" ];then
    if [ "$passwd_file" = "ip.txt" ]; then
        /usr/bin/expect <<-EOF
        set timeout 100000
        spawn ssh $hn
                expect {
                "*yes/no*" { send "yes\n"
                expect "*assword:" { send "$pw\n" } }
                "*assword:" { send "$pw\n" }
                        "*]#*"
                { send "wget $init_url/jdk.sh; chmod 755 jdk.sh; ./jdk.sh $baseurl; rm -rf jdk.sh\n" }
                        "*]#*"
                }
                        expect "*]#*"
EOF
    else
        /usr/bin/expect <<-EOF
        set timeout 100000
        spawn ssh $hn
                expect {
                "*yes/no*" { send "yes\n"
                expect "*]#*" { send "wget $init_url/jdk.sh; chmod 755 jdk.sh; ./jdk.sh $baseurl; rm -rf jdk.sh\n" } }
                "*]#*" { send "wget $init_url/jdk.sh; chmod 755 jdk.sh; ./jdk.sh $baseurl; rm -rf jdk.sh\n" }
                        "*]#*"
                }
                        expect "*]#*"
EOF
    fi
fi
done
