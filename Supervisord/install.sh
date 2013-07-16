#!/bin/bash

# Installing Supervisord

if [[ $EUID -ne 0 ]]; then
	echo -e "\033[34mThis script must be run as root\033[0m" 1>&2
	exit 1
fi

echo -e "\033[34m###### Installing Supervisord 3.0b2 ######\033[0m"

sudo rm -rf supervisor-3.0b2*
sudo rm -rf setuptools-0.9.5*
sudo rm -rf /etc/init.d/supervisord /etc/supervisord.*

cd /tmp
wget https://pypi.python.org/packages/source/s/supervisor/supervisor-3.0b2.tar.gz
wget https://pypi.python.org/packages/source/s/setuptools/setuptools-0.9.5.tar.gz
tar -xvzf supervisor-3.0b2.tar.gz
tar -xvzf setuptools-0.9.5.tar.gz
cd setuptools-0.9.5
sudo python setup.py install
cd ../supervisor-3.0b2
sudo python setup.py install

echo_supervisord_conf | sudo tee /etc/supervisord.conf
sudo mkdir /etc/supervisord.d

sudo sed -i -e 's/;\[inet_http_server\]/\[inet_http_server\]/' /etc/supervisord.conf
sudo sed -i -e 's/;port=127.0.0.1:9001/port=*:9001/' /etc/supervisord.conf
sudo sed -i -e 's/;\[include\]/\[include\]/' /etc/supervisord.conf
sudo sed -i -e 's/;files = relative\/directory\/\*.ini/files = supervisord.d\/\*/' /etc/supervisord.conf


sudo curl https://raw.github.com/gist/176149/88d0d68c4af22a7474ad1d011659ea2d27e35b8d/supervisord.sh > /etc/init.d/supervisord
sudo chmod +x /etc/init.d/supervisord
sudo update-rc.d supervisord defaults

service supervisord stop
service supervisord start