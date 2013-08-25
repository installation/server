#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo -e "\033[34mThis script must be run as root\033[0m" 1>&2
   exit 1
fi

preload() {
	echo -e "\033[34m###### Installing/Uninstalling Checklist plugin ######\033[0m"

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
	sudo -u $user -H wget http://redminecrm.com/license_manager/4200/redmine_issue_checklist-2_0_5.zip
	sudo -u $user -H unzip redmine_issue_checklist-2_0_5.zip
	#sudo bundle install --without development test sqlite postgresql
	sudo -u $user -H bundle exec rake redmine:plugins NAME=redmine_issue_checklist RAILS_ENV=production
	sudo rm -rf redmine_issue_checklist-2_0_5.zip
	echo -e "\033[34m###### Installation done ######\033[0m"
}

uninstall() {
	echo -e "\033[34m###### Uninstalling plugin ######\033[0m"
	sudo -u $user -H bundle exec rake redmine:plugins:migrate NAME=redmine_issue_checklist VERSION=0 RAILS_ENV=production
	sudo -u $user -H rm -rf redmine_issue_checklist/
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