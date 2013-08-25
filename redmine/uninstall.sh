#!/bin/bash

DIR=$(cd `dirname $0` && pwd)
NAME="Redmine"

# MySQL root password
rootpsw () {
	ROOTPSW=$(dialog --stdout --title "MySQL Server" \
		--backtitle "Installing $NAME" \
		--passwordbox "Please enter MySQL root password!" 8 50)

	if [[ -z ROOTPSW ]]; then
		dialog --title "Error" \
			--backtitle "Installing $NAME" \
			--msgbox "\n No password given." 6 50
		rootpsw
	fi
}

# Echo colored
e () {
	echo -e "\033[34m$1\033[0m"
}

e "###### Uninstalling Redmine 2.3.2 ######"

e "Removing user"
sudo deluser redmine
e "Removing usergroup"
sudo delgroup redmine
e "Removing home directory"
sudo rm -rf /usr/share/redmine
e "Removing temp files"
sudo rm -rf /tmp/redmine
e "Removing startup files"
sudo update-rc.d -f redmine remove
sudo rm /etc/init.d/redmine

# Database server
DB=$(dialog --stdout --backtitle "Removing $NAME" \
	--title "Choose Database" \
	--radiolist "Which database server do you use?" 10 34 2 \
	 1 "MySQL" on \
	 2 "PostgreSQL" off)

case "$DB" in
	2)
		sudo -u postgres psql -d template1 -c "CREATE ROLE redmine;"
		sudo -u postgres psql -d template1 -c "CREATE DATABASE redmine;"
		;;
	*)
		rootpsw
		mysql -u root -p$ROOTPSW -e "DROP USER 'redmine'@'localhost';"
		mysql -u root -p$ROOTPSW -e 'DROP DATABASE IF EXISTS `redmine`;'
		;;
esac

# Webserver
WS=$(dialog --stdout --backtitle "Installing $NAME" \
	--title "Choose Webserver" \
	--radiolist "Which webserver do you use?" 10 34 2 \
	 1 "Apache" on \
	 2 "Nginx" off)

case "$WS" in
	2)
		sudo rm -rf /etc/nginx/sites-enabled/redmine /etc/nginx/sites-available/redmine
		;;
	*)
		sudo a2dissite redmine
		sudo rm -rf /etc/apache2/sites-available/redmine
		;;
esac