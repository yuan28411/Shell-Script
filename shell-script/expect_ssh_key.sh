#!/bin/bash
#**************************************************************
#Author:                     dy
#QQ:                         2841184943
#Date:                       2019-11-13
#FileName:                   expect_ssh_key.sh
#Description:                Initialize the new server
#************************************************************
which expect  > /dev/null
if [ $? -ne 0 ];then
	yum -y install expect > /dev/null
fi
while true ;do
	read -p "Please enter IP address which you want to ssh(exit is Exit procedure):" IP
	if [ "$IP" == "exit" ];then
		exit 10
	fi
	echo "$IP" | grep -Eo "(([1-9][0-9]{0,1}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([1-9][0-9]{0,1}|1[0-9]{2}|2[0-4][0-9]|25[0-5])" > /dev/null
	if [ $? -ne 0 ];then
		echo "Please enter a legal ip address"
		continue
	fi
	expect << EOF

	spawn ssh-copy-id  -o StrictHostKeyChecking=no  root@${IP}
	expect {
		"(yes/no?)" {
			send "yes\n"
			expect "*password:" {send "dengyuan\n"}
			}
		"*password:" {send "dengyuan\n"}
	}
	expect eof
EOF
done
