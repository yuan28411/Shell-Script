#!/bin/bash
#**************************************************************
#Author:                     dy
#QQ:                         2841184943
#Date:                       2019-11-12
#FileName:                   install_redis.sh
#Description:                Initialize the new server
#************************************************************
yum -y install gcc make cmake 
if [ $? -eq 0 ] ;then
	Package="`ls redis*`"
	if [ -f $Package ] ; then
		echo "start to install redis"
		tar xvf $Package -C /usr/local/src/
		cd /usr/local/src/redis*
		if [ $? -eq 0 ]; then
			if [ ! -d /apps/redis ];then
		   		mkdir -p /apps/redis
			fi
			make PREFIX=/apps/redis install
			if [ $? -eq 0 ];then
				mkdir /apps/redis/{etc,logs,data,run}
				cp redis.conf /apps/redis/etc/;
				echo "net.core.somaxconn = 512" >> /etc/sysctl.conf
				echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
				sysctl -p
				echo never > /sys/kernel/mm/transparent_hugepage/enabled
				chmod +x /etc/rc.local
				echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local
				ln -s /apps/redis/bin/* /usr/bin/
			else 
				echo "Compile failed"
				exit 3
			fi
		else	
			echo "uncompress failed"
			exit 2
		fi
	else
		echo 'the package is not existed'
		exit 1
	fi
else 
	echo "please check you repo or network"
	exit 5
fi

echo "Prepare the startup script"
cat > /usr/lib/systemd/system/redis.service << EOF 
[Unit]  
Description=Redis persistent key-value database  
After=network.target  
After=network-online.target  
Wants=network-online.target  

[Service]  
#ExecStart=/usr/bin/redis-server /etc/redis.conf --supervised systemd  
ExecStart=/apps/redis/bin/redis-server /apps/redis/etc/redis.conf    --supervised systemd  
ExecReload=/bin/kill -s HUP $MAINPID    
ExecStop=/bin/kill -s QUIT $MAINPID  
Type=notify  
User=redis  
Group=redis  
RuntimeDirectory=redis  
RuntimeDirectoryMode=0755  

[Install]  
WantedBy=multi-user.target
EOF
id redis > /dev/null
if [ $? -ne 0 ];then
	useradd -s /sbin/nologin/ redis
fi
chown -R redis.redis /apps/redis/
systemctl enable --now redis

if [ $? -eq 0 ]; then
	echo "install redis is finshed"
else
	echo "there are some wrong in your system"
fi
