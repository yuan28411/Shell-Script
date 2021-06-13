#!/bin/bash
PACKAGE="jdk-8u212-linux-x64.tar.gz"
DIR="jdk1.8.0_212"
ls $PACKAGE > /dev/null
if [ $? -ne 0 ];then
	echo "$PACKAGE is not existed"
	exit 10
fi

tar xvf $PACKAGE -C /usr/local/src/
ln -s  /usr/local/src/$DIR  /usr/local/jdk

echo -e "JAVA_HOME=/usr/local/jdk\nCLASSPATH=.:\$JAVA_HOME/jre/lib/rt.jar:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar \nPATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile

. /etc/profile 
java -version > /dev/null
if [ $? -eq 0 ];then
    echo -e "\033[32msuccessfull\e[0m"
else
    echo -e "\033[31mfaild\e\0m"
fi


