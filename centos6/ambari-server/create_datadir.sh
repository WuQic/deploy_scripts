#!/bin/bash
#如果客户已创建/data目录且位于较大磁盘分区下，则通过符号链接减少磁盘占用

passwd_file=$1


#日志、元数据存储目录--$1

cd ../../..
data_dir=`echo $(dirname $(pwd))`
echo $data_dir
cd -

if [ $data_dir == "/" ]
then
	mkdir /data1 /data2
	
	echo "the data will be stored in /data1 and /data2, ensure disk capacity of the directories"
	
	cat $passwd_file |while read line;
	do
	pw=`echo $line|awk '{print $1}'`
	hn=`echo $line|awk '{print $2}'`
	local_hn=`hostname`

        if [ "$hn" != "$local_hn" ];then
            if [ "$passwd_file" = "ip.txt" ];then
	            /usr/bin/expect <<-EOF
	            set timeout 100000
	            spawn ssh $hn
	            	expect {
	            	"*yes/no*" { send "yes\n"
	            	expect "*assword:" { send "$pw\n" } }
	            	"*assword:" { send "$pw\n" }
	            		expect "*]#*"
	            	{ send "mkdir /data1 /data2\n" }
	            		expect "*]#*"
	            	}
	            		expect "*#*"
	            	send "mkdir /data1 /data2\n"
	            		expect "*]#*"
	EOF
	        else
	            /usr/bin/expect <<-EOF
	            set timeout 100000
	            spawn ssh $hn
	            	expect {
	            	"*yes/no*" { send "yes\n"
	            	expect "*]#*" { send "mkdir /data1 /data2\n" } }
	            	"*]#*" { send "mkdir /data1 /data2\n" }
	            		expect "*]#*"
	            	}
	            		expect "*#*"
	EOF
	        fi
        fi
	done
else
	mkdir -p $data_dir/data1 $data_dir/data2 
	ln -s $data_dir/data1 /
	ln -s $data_dir/data2 /

	cat $passwd_file |while read line;
	do
	pw=`echo $line|awk '{print $1}'`
	hn=`echo $line|awk '{print $2}'`
        local_hn=`hostname`

        if [ "$hn" != "$local_hn" ];then
        	if [ "$passwd_file" = "ip.txt" ];then
	            /usr/bin/expect <<-EOF
	            set timeout 100000
	            spawn ssh $hn
	            	expect {
	            	"*yes/no*" { send "yes\n"
	            	expect "*assword:" { send "$pw\n" } }
	            	"*assword:" { send "$pw\n" }
	            	"*]#*" { send "mkdir -p $data_dir/data1 $data_dir/data2\n" }
	            		expect "*]#*"
	            	send "ln -s $data_dir/data1 / \n"
	            		expect "*]#*"
	            	send "ln -s $data_dir/data2 / \n"
	            		expect "*]#*"
	            	}
	            		expect "*]#*"
	            	send "mkdir -p $data_dir/data1 $data_dir/data2\n"
	            		expect "*]#*"
	            	send "ln -s $data_dir/data1 / \n"
	            		expect "*]#*"
	            	send "ln -s $data_dir/data2 / \n"
	            		expect "*]#*"
	EOF
	        else
	            /usr/bin/expect <<-EOF
	            set timeout 100000
	            spawn ssh $hn
	            	expect {
	            	"*yes/no*" { send "yes\n"
	            	expect "*]#*" { send "mkdir -p $data_dir/data1 $data_dir/data2\n" } }
	            	"*]#*" { send "mkdir -p $data_dir/data1 $data_dir/data2\n" }
	            		expect "*]#*"
	            	}
	            		expect "*]#*"
	            	send "ln -s $data_dir/data1 / \n"
	            		expect "*]#*"
	            	send "ln -s $data_dir/data2 / \n"
	            		expect "*]#*"
	EOF
	        fi
        fi
	done
fi
