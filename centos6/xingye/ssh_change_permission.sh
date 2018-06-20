#!/bin/bash

cd `dirname $0`

declare -a iparray

loacl_ip=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`

while read line;
do
	ip=`echo  $line | awk '{print $1}'`
	iparray=("${iparray[@]}" "$ip")
done < ../ambari-server/host

echo "length : ${#iparray[@]}"

for ip in ${iparray[@]}; do
	/usr/bin/expect <<-EOF
	set timeout 100000
	spawn scp change_permission.sh root@${ip}:/tmp/
	expect {
		"*yes/no*" { send "yes\n";exp_continue}
		"*assword*" { send "${pw}\n";exp_continue}
		"*]#*" { send "exit\n"}
	}
EOF
	ssh -tt root@${ip} <<-EOF
	su $user -c 'sh /tmp/change_permission.sh' 
	exit
EOF

	if [[ $loacl_ip == $ip ]];then
		su $user -c 'sh /tmp/change_permission.sh' 
	else 
		ssh -tt root@${ip} <<-EOF
		su $user -c 'sh /tmp/change_permission.sh' 
		exit
EOF
	fi
done

cd -