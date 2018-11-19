echo "==================="
echo "     RSA KEY"
echo "==================="
read -p "Enter comment(Default:'akarasso@student.42.fr'):" RSA_COMMENT
RSA_COMMENT=${RSA_COMMENT:-"akarasso@student.42.fr"}
read -p "Key path(Default:~/.ssh):" RSA_KEY
RSA_KEY=${RSA_KEY:-~/.ssh}
if [ ! -e $RSA_KEY/id_rsa ] ; then
	ssh-keygen -t rsa -b 4096 -C $RSA_COMMENT -f $RSA_KEY/id_rsa
fi
echo "==================="
echo "       SSH"
echo "==================="
read -p "Enter default user(Default:'hoax'):" SSH_USER
SSH_USER=${SSH_USER:-hoax}
read -p "Enter ssh ip(Default:127.0.0.1):" SSH_IP
SSH_IP=${SSH_IP:-127.0.0.1}
read -p "Enter ssh port(Default:2222):" SSH_PORT
SSH_PORT=${SSH_PORT:-2222}
scp -P $SSH_PORT -r $PWD/app $RSA_KEY $PWD/install-config.sh $PWD/crontab-survey.sh $SSH_USER@$SSH_IP:~/
