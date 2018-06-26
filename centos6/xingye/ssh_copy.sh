#!/bin/bash
SERVERS=$1
HOSTNAMES=$2
PASSWORD=$3

auto_ssh_copy_id() {
    expect -c "set timeout -1;
        spawn ssh-copy-id $1;
        expect {
            *(yes/no)* {send -- yes\r;exp_continue;}
            *assword:* {send -- $2\r;exp_continue;}
            eof        {exit 0;}
        }";
}

auto_ssh() {
    expect -c "set timeout -1;
        spawn ssh $1;
        expect {
            *(yes/no)* {send -- yes\r;exp_continue;}
            eof        {exit 0;}
        }";
}

ssh_copy_id_to_all() {
    for SERVER in $SERVERS
    do
        auto_ssh_copy_id $SERVER $PASSWORD
    done
}

ssh_by_host_name(){
    for HOSTNAME in $HOSTNAMES
    do
        auto_ssh $HOSTNAME 
    done
}

ssh_copy_id_to_all
ssh_by_host_name