#!/bin/bash
#**************************************************************
#Author:                     dy
#QQ:                         2841184943
#Date:                       2019-11-25
#FileName:                   openvpn.sh
#Description:                This script an manager vpn user
#************************************************************
yum -y install expect > /dev/null
sign_certificate() {
	cd /etc/openvpn/easyrsa-client/3/
	PASS=`cat /dev/urandom  | tr -Cd "[:alnum:]" | head -c 10`
expect << EOF
cd /etc/openvpn/easyrsa-client/3/
spawn ./easyrsa gen-req $1
expect {
	"Enter PEM pass phrase:" { send "$PASS\n"; exp_continue; }
	"Verifying - Enter PEM pass phrase:" { send "$PASS\n";exp_continue; }
	"]:" { send "\n";exp_continue;}
expect eof
}
EOF
	if [ $? -eq 0 ];then
		cd /etc/openvpn/easyrsa-server/3/
		/etc/openvpn/easyrsa-server/3/easyrsa import-req /etc/openvpn/easyrsa-client/3/pki/reqs/$1.req $1
expect << EOF
cd /etc/openvpn/easyrsa-server/3/
spawn /etc/openvpn/easyrsa-server/3/easyrsa sign client $1
expect {
	"Confirm request details:" { send "yes\n" }
}
expect eof
EOF
		mkdir /etc/openvpn/client/$1 > /dev/null
		echo "$1             $PASS"  > pass.txt
		echo "$1             $PASS"  >> /etc/openvpn/client/pass.txt
		cd /etc/openvpn/client/$1
		cp /etc/openvpn/easyrsa-client/3/pki/private/$1.key .
		cp /etc/openvpn/easyrsa-server/3/pki/ca.crt .
		cp /etc/openvpn/easyrsa-server/3/pki/issued/$1.crt .
cat > client.ovpn << EOF
client
dev tun
proto tcp
remote 172.18.5.101 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert $1.crt
key $1.key
remote-cert-tls server
#tls-auth ta.key 1
cipher AES-256-CBC
verb 3
EOF
	cd ../
	zip $1.zip $1/*
	return 0
	else
		echo "create require faild" 
		exit 0
	fi
}

revoke_certificate(){
	if [ $? -eq 0 ];then
		cd /etc/openvpn/easyrsa-server/3/
		./easyrsa revoke $1
		./easyrsa gen-crl 
		sed -i "/$1/d" /etc/openvpn/client/pass.txt
		rm -rf /etc/openvpn/client/$1*
		rm -f /etc/openvpn/easyrsa-client/3/pki/private/$1.key
		rm -f /etc/openvpn/easyrsa-server/3/pki/issued/$1.crt
		rm -f /etc/openvpn/easyrsa-client/3/pki/reqs/$1.req
		rm -f /etc/openvpn/easyrsa-server/3/pki/reqs/$1.req
		systemctl restart openvpn@server
		return 0
	else
		echo "revoke faild,is this user exist?"
		exit 2
	fi
}



select Choose in "sign certificate" "revoke certificate"  "resign certificate"
do 
	case $Choose in
		"sign certificate")
			echo "Start to sign a new certificate"
			read -p "Please enter user'name and id(Exp:dengyuan):" name
			sign_certificate ${name}
			if [ $? -eq 0 ];then
				echo "sign successfull"
			fi
			;;

		"revoke certificate")
			 echo "Start to revoke certificate"
			 read -p "Please enter user'name and id (Exp:dengyuan):" name
			 revoke_certificate ${name}
			 if [ $? -eq 0 ];then
			 	echo "revoke successfull"
			fi
			;;
		"resign certificate")
			echo "Start to resign certificate"
			read -p "Please enter user'name and id (Exp:dengyuan):" name
			revoke_certificate ${name}
			sign_certificate ${name}
			if [ $? -eq 0 ];then
				echo "resign successfull"
			fi
	esac
done
