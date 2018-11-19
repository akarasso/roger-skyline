#!/bin/bash
if ! [ -e ~/.crontest ] ; then
	sudo cp /etc/crontab ~/.crontest
fi
if ! cmp /etc/crontab ~/.crontest >/dev/null 2>&1
then
	sudo cp /etc/crontab ~/.crontest
	echo "crontab has been edited" | mail -s "Cron service" -a "From : crontabservice@student.42.fr" a.karassouloff@gmail.com
	echo "crontab has been edited" | mail -s "Cron service" -a "From : crontabservice@student.42.fr" root@localhost
fi
