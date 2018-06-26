#!/bin/bash

cd `dirname $0`

user=$1
pw="123456"

declare -a iparray

loacl_ip=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`

while read line;
do
	ip=`echo  $line | awk '{print $1}'`
	hn=`echo  $line | awk '{print $2}'`
	iparray=("${iparray[@]}" "$ip")
	hnarray=("${hnarray[@]}" "$hn")
done < ../ambari-server/host

echo "length : ${#iparray[@]}"

for ip in ${iparray[@]}; do
	if [[ $loacl_ip == $ip ]];then
		echo "add user $user"
		adduser $user
		echo -ne "${pw}\n${pw}\n" | passwd $user
		su $user -c 'ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa'
	else
		ssh -tt root@$ip <<-EOF
		echo "add user $user"
		adduser $user
		echo -ne "${pw}\n${pw}\n" | passwd $user
		su $user -c 'ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa'
		exit
EOF
	fi
done


for ip in ${iparray[@]}; do
	/usr/bin/expect <<-EOF
	set timeout 100000
	spawn scp ssh_copy.sh root@${ip}:/tmp/
	expect {
		"*yes/no*" { send "yes\n";exp_continue}
		"*assword*" { send "${pw}\n";exp_continue}
		"*]#*" 
	}
EOF
done


for ip in ${iparray[@]}; do
	echo ">>>>"$loacl_ip
	echo "<<<<"$ip
	if [[ $loacl_ip == $ip ]];then
		su $user -c "sh /tmp/ssh_copy.sh '${iparray[*]}' $pw"
	else 
		ssh -tt root@$ip <<-EOF
		yum install -y expect
		su $user -c "sh /tmp/ssh_copy.sh '${iparray[*]}' $pw"
		exit
EOF
	fi
done

cd -