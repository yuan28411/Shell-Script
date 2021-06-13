#!/bin/bash
DATE=`date "+%F_%T"`
METHOD=$1
BRANCH=$2
GROUP_LIST=$3
PROJECT=$4

function IP_list(){
	if [[ ${GROUP_LIST} == "online-group1" ]];then
    	Server_IP="192.168.38.52"
		echo "Server_IP=${Server_IP}"

    elif [[ ${GROUP_LIST} == "online-group2" ]];then
        Server_IP="192.168.38.53"
        echo "Server_IP=${Server_IP}"
    
    elif [[ ${GROUP_LIST} == "online-all" ]];then
        Server_IP="192.168.38.52 192.168.38.53"
        echo "Server_IP=${Server_IP}"
    fi
}

function clone_code(){
  rm -rf /data/git/linux38/$PROJECT
  if [ -d /data/git/linux38/ ];then
  	cd /data/git/linux38 
  else 
	mkdir /data/git/linux38 -p
  fi
  git clone -b ${BRANCH} git@www.dy.com:test/test-services.git
}

function scanner_code(){
  cd /data/git/linux38/$PROJECT 
  #/usr/local/src/sonar-scanner-4.2.0.1873-linux/bin/sonar-scanner
}

function make_zip(){
  cd /data/git/linux38/$PROJECT &&  zip -r $PROJECT.zip ./*
}


function node_down(){
for node in ${Server_IP};do
	ssh root@192.168.38.50  "echo disable server linux38-web/${node} | socat stdio   /run/haproxy/admin.sock"
	ssh root@192.168.38.51  "echo disable server linux38-web/${node} | socat stdio   /run/haproxy/admin.sock"
    if [ $? -eq 0 ];then
		echo "${node} 从负载均衡下线成功"
	fi
    #echo "${node}"
done
}

function stop_tomcat(){
  for node in ${Server_IP};do
    echo "${node} 开始停止tomcat"
    ssh www@${node}   "systemctl stop tomcat"
    if [ $? -eq 0 ];then
            echo "${node} tomcat停止成功"
        fi
  done
  sleep 5
}

function scp_zipfile(){
  for node in ${Server_IP};do
    scp /data/git/linux38/$PROJECT/$PROJECT.zip  www@${node}:/data/tomcat/tomcat_appdir/$PROJECT-${DATE}.zip
    ssh www@${node} "unzip /data/tomcat/tomcat_appdir/$PROJECT-${DATE}.zip -d /data/tomcat/tomcat_webdir/$PROJECT-${DATE} && rm -rf /data/tomcat_webdir/myapp && ln -sv /data/tomcat/tomcat_webdir/$PROJECT-${DATE} /data/tomcat_webdir/myapp"
  done
}

function start_tomcat(){
  for node in ${Server_IP};do
    ssh www@${node}   "systemctl  start tomcat"
    #sleep 5
  done
}

function web_test(){
  sleep 20
  for node in ${Server_IP};do
    NUM=`curl -s  -I -m 10 -o /dev/null  -w %{http_code}  http://${node}:8080/myapp/index.html`
    if [[ ${NUM} -eq 200 ]];then
       echo "${node} 测试通过,即将添加到负载"
       add_node ${node}
    else
       echo "${node} 测试失败,请检查该服务器是否成功启动tomcat"
    fi
  done
}

function add_node(){
    for node in ${Server_IP};do
        ssh root@192.168.38.50  "echo enable server linux38-web/${node} | socat stdio   /run/haproxy/admin.sock"
        ssh root@192.168.38.51  "echo enable server linux38-web/${node} | socat stdio   /run/haproxy/admin.sock"
        if [ $? -eq 0 ];then
            echo "${node} 从负载均衡上线成功"
        fi
    #echo "${node}"
    done
}


function rollback_last_version(){
  for node in ${Server_IP};do
   NOW_VERSION=`ssh www@${node} ""/bin/ls -l  -rt  /data/tomcat_webdir/myapp |  awk -F '->' '{print $2}' |tail -n1""`
   NOW_VERSION=`basename ${NOW_VERSION}`
   echo $NOW_VERSION
   NAME=`ssh www@${node} ""ls -l -rt /data/tomcat/tomcat_webdir/ |grep -B 1 ${NOW_VERSION}| head -n1 |awk '{print $9}'""`
   ssh www@${node} "rm -rf  /data/tomcat_webdir/myapp && ln -sv /data/tomcat/tomcat_webdir/$NAME /data/tomcat_webdir/myapp"
  done 
}


main(){
   case $1  in
      deploy)
        IP_list;        
        clone_code;
        scanner_code;
        make_zip;
        node_down;
        stop_tomcat;
        scp_zipfile;
        start_tomcat;
        web_test;
        add_node;
         ;;
       rollback)
        IP_list;
        echo ${Server_IP}
        node_down;
        stop_tomcat;
        rollback_last_version;
        start_tomcat;
        web_test;
        add_node;
         ;;
    esac
}

main $1 $2 $3
