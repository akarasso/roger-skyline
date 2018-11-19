chmod +x *.sh
echo "==================================="
echo "        /etc/apt/source.list"
echo "==================================="

apt update && apt upgrade -y

echo "==================================="
echo "             LAN ADDR"
echo "==================================="

read -p "Ip Address('Default:10.0.2.5'):" ADDRV4
ADDRV4=${ADDRV:-10.0.2.5}

read -p "Netmask('Default'):255.255.255.252" NETMASK
NETMASK=${NETMASK:-255.255.255.252}

echo "allow-hotplug enp0s8">> /etc/network/interfaces
echo "iface enp0s8 inet static">> /etc/network/interfaces
echo "netmask $NETMASK">> /etc/network/interfaces
echo "address $ADDRV4">> /etc/network/interfaces

echo "==================================="
echo "             SSH"
echo "==================================="

read -p "Futur ssh port(Default:2222):" SSH_PORT
SSH_PORT=${SSH_PORT:-2222}

read -p "Futur ssh user(Default:hoax):" SSH_USER
SSH_USER=${SSH_USER:-hoax}

echo "Port $SSH_PORT
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile      .ssh/authorized_keys
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server" > sshd_config
if [ ! -e /etc/ssh/sshd_config ] ; then
	mv /etc/ssh/sshd_config /etc/ssh/sshd_config.back
fi
cp sshd_config /etc/ssh/sshd_config
cat .ssh/id_rsa.pub > /home/$SSH_USER/.ssh/authorized_keys


echo "==================================="
echo "             POSTFIX"
echo "==================================="
read -p "Enter email-address(Default:debian):" POSTFIX_ADDR
POSTFIX_ADDR=${POSTFIX_ADDR:-debian_roger-skyline}
debconf-set-selections <<< "postfix postfix/mailname string $POSTFIX_ADDR"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix


echo "==================================="
echo "             IPTABLES"
echo "==================================="
echo "Gen file"
echo "#!/bin/bash

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

#If i accept PORTSENTRY WORKS but i prefer to drop everything
iptables -P INPUT DROP

iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

#Malformed packet
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

#SSH
iptables -A INPUT -p tcp -m tcp --dport $SSH_PORT -j ACCEPT

#ANTI DDOS

iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 588:65535 -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
iptables -F OUTPUT  # remove your existing OUTPUT rule which becomes redundant
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -m state --state NEW -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
" > /root/iptables.sh


chmod +x iptables.sh

echo "==================================="
echo "             FAIL2BAN"
echo "==================================="

apt install fail2ban -y


echo "==================================="
echo "             CRON"
echo "==================================="

echo '00 4    * * 1   root    apt update > /var/log/update-script.log && apt upgrade -y >> /var/log/update-script.log' >> /etc/crontab
echo '@reboot         root    apt update > /var/log/update-script.log && apt upgrade -y >> /var/log/update-script.log' >> /etc/crontab
echo '00 0    * * *   root    /root/crontab-survey.sh' >> /etc/crontab
echo '@reboot         root    /root/iptables.sh' >> /etc/crontab
mv crontab-survey.sh /root/
