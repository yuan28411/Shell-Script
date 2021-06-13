#!/bin/bash
PACKAGE="apache-tomcat-8.5.47.tar.gz"
DIR=`echo $PACKAGE | awk -F '.tar' '{print $1}'`
mkdir /apps
tar xvf $PACKAGE -C /apps
ln -s /apps/$DIR /apps/tomcat

useradd -m www -u 2019 -s /bin/bash
mkdir /data/tomcat/tomcat_appdir -p
mkdir /data/tomcat/tomcat_webdir
mkdir /data/tomcat/tomcat_webdir/myapp
echo SERVER_IP > /data/tomcat/tomcat_webdir/myapp/index.html


sed -Ei "/appBase/s#(.*=).*# \1 \"/data/tomcat_webdir/\"#" /apps/tomcat/conf/server.xml

cat > /lib/systemd/system/tomcat.service  << EOF
[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking
Environment="JAVA_HOME=/usr/local/jdk"
ExecStart=/apps/tomcat/bin/catalina.sh start
ExecReload=/apps/tomcat/bin/catalina.sh stop && /apps/tomcat/bin/catalina.sh start
ExecStop=/apps/tomcat/bin/catalina.sh stop

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start tomcat
