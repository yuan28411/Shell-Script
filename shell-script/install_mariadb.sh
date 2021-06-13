#!/bin/bash
#create group use
groupadd -r -g 336 mysql > /dev/null
useradd -r -g mysql -u 336 -s /sbin/nologin -d /data/mysql mysql  > /dev/null
if [ $? -eq 0 ];then
    echo "add user successfull"
else 
    echo "and user faild"
    exit 1
fi
#tar and link  
if [ -f mariadb-10.2.27-linux-x86_64.tar.gz ];then
      tar xvf mariadb-10.2.27-linux-x86_64.tar.gz -C /usr/local/
      cd  /usr/local/
      ln -s mariadb-10.2.27-linux-x86_64/ mysql
      chown -R root.root /usr/local/mysql/
      if [ $? -eq 0 ];then
           echo "解包成功"
       else 
            echo "解包失败"
            exit 2
       fi
else
     echo "please check package is existed ?"
     exit 3
fi

#PATH 修改变量PATH，让安装包自带脚本可以执行
echo "PATH=/usr/local/mysql/bin:$PATH" >> /etc/profile
source /etc/profile  
mkdir /data/mysql -p

#data准备数据库数据及目录
chown mysql.mysql /data/mysql/  
cd /usr/local/mysql 
./scripts/mysql_install_db --datadir=/data/mysql --user=mysql  

#service  准备mysql服务端的配置文件
mkdir  /etc/mysql
cp /usr/local/mysql/support-files/my-huge.cnf  /etc/my.cnf
sed -i "/\[mysqld\]/adatadir=\/data\/mysql" /etc/my.cnf  

#start script 准备服务启动脚本
cp /usr/local/mysql/support-files/mysql.server  /etc/init.d/mysqld 
chkconfig --add mysqld
service mysqld start


echo 'start to install nfs'
yum -y install nfs-utils
mkdir -p /data/nginx
echo '/data/nginx *(rw,no_root_squash)'  >> /etc/exports
systemctl enable --now nfs
echo 'finished'