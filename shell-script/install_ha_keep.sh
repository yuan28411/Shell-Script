#!/bin/bash
yum -y install libtermcap-devel ncurses-devel libevent-devel readline-devel 
if [ -f lua-5.3.5.tar.gz ];then
	tar xvf lua-5.3.5.tar.gz -C /usr/local/src/
	cd /usr/local/src/lua-5.3.5
	make linux
	cd

	if [ -f haproxy-2.0.8.tar.gz ];then
		tar xvf haproxy-2.0.8.tar.gz -C /usr/local/src/
		cd /usr/local/src/haproxy-2.0.8
			yum -y install gcc gcc-c++ glibc glibc-devel pcre pcre-devel openssl  openssl-devel systemd-devel net-tools vim iotop bc  zip unzip zlib-devel lrzsz tree screen lsof tcpdump wget ntpdate
			make  ARCH=x86_64 TARGET=linux-glibc USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1x USE_SYSTEMD=1x USE_CPU_AFFINITY=1 USE_LUA=1 LUA_INC=/usr/local/src/lua-5.3.5/src/ LUA_LIB=/usr/local/src/lua-5.3.5/src/ PREFIX=/usr/local/haproxy 
			make install PREFIX=/usr/local/haproxy 
			cp haproxy  /usr/sbin/

cat > /usr/lib/systemd/system/haproxy.service << EOF
[Unit]
Description=HAProxy Load Balancer
After=syslog.target network.target
 
[Service]
ExecStartPre=/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg  -c -q
ExecStart=/usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /var/lib/haproxy/haproxy.pid
ExecReload=/bin/kill -USR2 $MAINPID
  
[Install]
 WantedBy=multi-user.target
EOF


			mkdir  /etc/haproxy
cat > /etc/haproxy/haproxy.cfg << EOF
global
maxconn 100000
chroot /usr/local/haproxy
stats socket /var/lib/haproxy/haproxy.sock mode 600 level admin
uid 99
gid 99
daemon
#nbproc 4
#cpu-map 1 0
#cpu-map 2 1
#cpu-map 3 2
#cpu-map 4 3
pidfile /var/lib/haproxy/haproxy.pid
log 127.0.0.1 local3 

defaults
option http-keep-alive
option forwardfor
#maxconn 100000
mode http
timeout connect 300000ms
timeout client  300000ms
timeout server  300000ms
 
listen stats
mode http
bind 0.0.0.0:9999
stats enable
log global
stats uri  /haproxy-status
stats auth haadmin:123456

listen web
        mode http
        bind 172.18.5.12:80
        balance roundrobin
        server 172.18.5.3 172.18.5.3:80 check inter 3000 fall 3 rise 5
        server 172.18.5.4 172.18.5.4:80 check inter 3000 fall 3 rise 5
listen mysql
        bind 172.18.5.11:3306
        mode tcp
        server 172.18.5.5 172.18.5.5:3306 check inter 3000 fall 3 rise 5
EOF

			mkdir  /var/lib/haproxy
			chown -R 99.99 /var/lib/haproxy/
			sed -ri  '/ModLoad imudp/s/^#(.*)/\1/' /etc/rsyslog.conf
			sed -ri  '/UDPServerRun 514/s/^#(.*)/\1/' /etc/rsyslog.conf
			sed -i '/local7/alocal3.*      /var/log/haproxy.log' /etc/rsyslog.conf

			systemctl daemon-reload
			systemctl restart rsyslog
			systemctl enable --now haproxy

else
		echo "the haproxy-2.0.8.tar.gz is not existed"
	fi


else
	echo "the lua package is not existed"
fi
cd
echo "start install keepalive"
yum -y install psmisc
tar -xvf keepalived-2.0.19.tar.gz -C /usr/local/src/
cd /usr/local/src/keepalived-2.0.19/
yum install libnfnetlink-devel libnfnetlink ipvsadm  libnl libnl-devel  libnl3 libnl3-devel   lm_sensors-libs net-snmp-agent-libs net-snmp-libs  openssh-server openssh-clients  openssl openssl-devel automake iproute  -y
./configure --prefix=/usr/local/keepalived --disable-fwmark
make && make install
cp /usr/local/src/keepalived-2.0.19/keepalived/etc/init.d/keepalived /etc/sysconfig/keepalived.sysconfig
cp /usr/local/src/keepalived-2.0.19/keepalived/keepalived.service /usr/lib/systemd/system/
cp /usr/local/src/keepalived-2.0.19/bin/keepalived /usr/sbin/
mkdir /etc/keepalived


