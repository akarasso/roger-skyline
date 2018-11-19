#!/bin/bash

chmod +x *.sh

echo "==================================="
echo "        /etc/apt/source.list"
echo "==================================="

apt update && apt upgrade -y && apt install -y mailutils openssl vim
apt install -y apache2

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
Subsystem       sftp    /usr/lib/openssh/sftp-server
MaxAuthTries 1" > sshd_config
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

iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -N f2b-sshd
iptables -N port-scanning
iptables -A INPUT -p tcp -m multiport --dports $SSH_PORT -j f2b-sshd
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

#Anti Scanning
iptables -N port-scanning
iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
iptables -A port-scanning -j DROP

#Open ports for web
iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT" > /root/iptables.sh
chmod +x /root/iptables.sh

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

echo "==================================="
echo "             APP"
echo "==================================="

rm -rf /var/www/html/*
cp -R app/* /var/www/html
mkdir -p /etc/ssl/localcerts
openssl req -new -x509 -days 365 -nodes -out /etc/ssl/localcerts/apache.pem -keyout /etc/ssl/localcerts/apache.key
chmod 600 /etc/ssl/localcerts/apache*
echo '<IfModule mod_ssl.c>
        <VirtualHost _default_:443>
                ServerAdmin webmaster@localhost
                DocumentRoot /var/www/html
                ErrorLog ${APACHE_LOG_DIR}/error.log
                CustomLog ${APACHE_LOG_DIR}/access.log combined
                SSLEngine on
                SSLCertificateFile      /etc/ssl/localcerts/apache.pem
                SSLCertificateKeyFile /etc/ssl/localcerts/apache.key
                <FilesMatch "\.(cgi|shtml|phtml|php)$">
                                SSLOptions +StdEnvVars
                </FilesMatch>
                <Directory /usr/lib/cgi-bin>
                                SSLOptions +StdEnvVars
                </Directory>
        </VirtualHost>
</IfModule>' > /etc/apache2/sites-available/site-ssl.conf
echo '<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/html
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>' > /etc/apache2/sites-available/site.conf
a2enmod ssl
a2ensite site
a2ensite site-ssl
reboot
