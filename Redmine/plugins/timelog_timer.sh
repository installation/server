#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo -e "\033[34mThis script must be run as root\033[0m" 1>&2
   exit 1
fi

preload() {
	echo -e "\033[34m###### Installing/Uninstalling Timelog Timer plugin ######\033[0m"

	echo -e "\033[34mPlease enter your redmine install path: \033[0m[/usr/share/redmine]"
	read install_path
	install_path=${install_path:-/usr/share/redmine}

	echo -e "\033[34mPlease enter your redmine username: \033[0m[redmine]"
	read user
	user=${user:-redmine}

	cd $install_path/plugins/
}

install() {
	echo -e "\033[34m###### Installing plugin ######\033[0m"
	sudo -u $user -H git clone https://github.com/behigh/redmine_timelog_timer.git timelog_timer
	#sudo bundle install --without development test sqlite postgresql
	sudo -u $user -H bundle exec rake redmine:plugins NAME=timelog_timer RAILS_ENV=production
	echo -e "\033[34m###### Installation done ######\033[0m"
}

uninstall() {
	echo -e "\033[34m###### Uninstalling plugin ######\033[0m"
	sudo -u $user -H bundle exec rake redmine:plugins:migrate NAME=timelog_timer VERSION=0 RAILS_ENV=production
	sudo -u $user -H rm -rf timelog_timer/
	echo -e "\033[34m###### Uninstallation done ######\033[0m"
}

case "$1" in
  install)
		preload
        install
        ;;
  uninstall)
		preload
        uninstall
        ;;
  reinstall)
		preload
        uninstall
        install
        ;;
  *)
        echo "Usage: sudo ./checklist.sh {install|uninstall|reinstall}" >&2
        exit 1
        ;;
esac


sudo service redmine restart