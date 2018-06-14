#!/bin/bash

cd `dirname $0`

user=$1
pw="123456"

declare -a iparray

while read line;
do
	ip=`echo  $line | awk '{print $1}'`
	iparray=("${iparray[@]}" "$ip")
done < ../ambari-server/host

echo "length : ${#iparray[@]}"

for ip in ${iparray[@]}; do
	ssh -tt root@${ip} <<-EOF
	echo "add user $user"
	adduser $user
	echo -ne "${pw}\n${pw}\n" | passwd $user
	su $user -c 'ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa'
	exit
EOF
done


for ip in ${iparray[@]}; do
	/usr/bin/expect <<-EOF
	set timeout 100000
	spawn scp ssh_copy.sh root@${ip}:/tmp/
	expect {
		"*yes/no*" { send "yes\n";exp_continue}
		"*assword*" { send "${pw}\n";exp_continue}
		"*]#*" { send "exit\n"}
	}
EOF
	ssh -tt root@${ip} <<-EOF
	yum install -y expect
	su $user -c 'sh /tmp/ssh_copy.sh "${iparray[*]}" $pw' 
	exit	
EOF
done

cd -