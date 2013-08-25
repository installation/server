#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo -e "\033[34mThis script must be run as root\033[0m" 1>&2
   exit 1
fi

DIR=$(cd `dirname $0` && pwd)

preload() {
	echo -e "\033[34m###### Installing/Uninstalling Owncloud ######\033[0m"

	echo -e "\033[34mPlease enter your Owncloud install path: \033[0m[/opt/owncloud/]"
	read install_path
	install_path=${install_path:-/opt/owncloud/}

	echo -e "\033[34mPlease enter your Owncloud data path: \033[0m[/home/owncloud/]"
	read data_path
	data_path=${data_path:-/home/owncloud/}
}

install() {
	echo -e "\033[34m###### Installing Owncloud ######\033[0m"
	echo -e "\033[34mInstalling dependencies\033[0m"
	sudo apt-get install -y apache2 php5 php5-gd php-xml-parser php5-intl
	sudo apt-get install -y php5-sqlite php5-mysql smbclient curl libcurl3 php5-curl
	echo -e "\033[34mDownloading source\033[0m"
	cd /tmp
	wget http://mirrors.owncloud.org/releases/owncloud-4.5.7.tar.bz2
	tar -xjf owncloud-4.5.7.tar.bz2
	sudo mkdir -p $install_path $data_path
	sudo cp -r owncloud/* $install_path
	sudo cp $DIR/vhost.conf /etc/apache2/sites-available/owncloud

	echo -e "\033[34mPlease enter your hostname: \033[0m[owncloud.localhost]"
	read host
	host=${host:-owncloud.localhost}
	sudo sed -i -e "s/\${HOST}/$host/" /etc/apache2/sites-available/owncloud
	sudo sed -i -e "s|\${PATH}|$install_path|g" /etc/apache2/sites-available/owncloud
	sudo chown -R www-data.www-data $install_path $data_path

	echo -e "\033[34mSetting up Apache\033[0m"
	sudo mkdir -p /var/log/apache2/owncloud/
	sudo a2ensite owncloud
	sudo service apache2 reload

	echo -e "\033[34m###### Installation done ######\033[0m"
}

uninstall() {
	echo -e "\033[34m###### Uninstalling Owncloud ######\033[0m"
	sudo rm -rf $install_path
	sudo rm -rf $data_path
	echo -e "\033[34mPlease delete the MySQL database manually\033[0m"
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