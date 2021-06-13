#!/bin/bash
#**************************************************************
#Author:                     dy
#QQ:                         2841184943
#Date:                       2019-11-08
#FileName:                   install_php_nginx.sh
#Description:                Initialize the new server
#************************************************************
echo "start to install nginx"
yum install -y vim lrzsz tree screen psmisc lsof tcpdump wget  ntpdate  gcc gcc-c++ glibc glibc-devel pcre pcre-devel openssl  openssl-devel systemd-devel net-tools iotop bc  zip unzip zlib-devel bash-completion nfs-utils automak libxml2  libxml2-devel libxslt libxslt-devel perl perl-ExtUtils-Embed
if [ -f nginx-1.16.1.tar.gz ];then
        tar -xvf nginx-1.16.1.tar.gz -C /usr/local/src
        cd /usr/local/src/nginx-1.16.1
        if [ $? -eq 0 ];then
                ./configure --prefix=/apps/nginx --user=nginx --group=nginx --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_stub_status_module --with-http_gzip_static_module --with-pcre --with-stream --with-stream_ssl_module --with-stream_realip_module
                make -j 4 && make install                                                                           
                id nginx
                if [ $? -ne 0 ];then
                        useradd nginx -s /sbin/nologin -u 2000
                fi
                chown -R nginx.nginx /apps/nginx
cat > /usr/lib/systemd/system/nginx.service << EOF
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/bin/rm -f /run/nginx.pid
ExecStartPre=/apps/nginx/sbin/nginx -t
ExecStart=/apps/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=process
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
		sed -ri '/nobody/auser nginx;' /apps/nginx/conf/nginx.conf
		sed -ri '/pid/a pid        /run/nginx.pid;' /apps/nginx/conf/nginx.conf
		mkdir /apps/nginx/conf/conf.d
		sed -ri '/charset koi8-r/a   include /apps/nginx/conf/conf.d/*.conf;' /apps/nginx/conf/nginx.conf
		sed -ri 's/(index)(.*)(index.html)(.*)/\1 index.php \2\3\4/' /apps/nginx/conf/nginx.conf
cat > /apps/nginx/conf/conf.d/php.conf << EOF
location ~ \.php$ {
	root           /apps/nginx/html;
    fastcgi_pass   127.0.0.1:9000;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
    include        fastcgi_params;
}
EOF
		systemctl daemon-reload
        systemctl enable --now nginx
		cd
        	if [ $? -eq 0 ];then
				echo "nginx is runing "
       		else
            	echo "configure script of start is fiald"
                  exit 4
        	fi
        else
                echo "unzip packages fail"
                exit 3
        fi
else 
        echo "the nginx install package is not existed"
        exit 2
fi


if [ -f php-7.3.10.tar.xz ];then
	tar xvf php-7.3.10.tar.xz -C /usr/local/src/
	cd /usr/local/src/php-7.3.10

./configure --prefix=/apps/php --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-openssl --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --enable-mbstring --enable-xml --enable-sockets --enable-fpm --enable-maintainer-zts --disable-fileinfo 
	make -j 4 && make install
	cp php.ini-production  /etc/php.ini
	cp sapi/fpm/php-fpm.service /usr/lib/systemd/system/php-fpm.service
	cd /apps/php/etc
	cp php-fpm.conf.default  php-fpm.conf
	cd php-fpm.d/
	cp www.conf.default www.conf
	sed -ri 's#(user =).*#\1 nginx#' www.conf
	sed -ri 's#(group =).*#\1 nginx#' www.conf
	systemctl daemon-reload
	systemctl enable --now php-fpm.service
	cd
else
	echo 'php package is not exist'
               exit 1
fi


echo "172.18.5.5:/data/nginx                    /apps/nginx/html        nfs     defaults,_netdev 0 0 " >> /etc/fstab
mount -a

if [ -f wordpress-5.2.3-zh_CN.zip ];then
	unzip wordpress-5.2.3-zh_CN.zip
    	mv wordpress/* /apps/nginx/html/
	chown -R nginx.nginx /apps/nginx/html
    echo -e "\e[41mFinished!\e[0m"
else 
	echo "the wordpress package is not existed"
fi
