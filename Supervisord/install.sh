#!/bin/bash

# # Script to install Supervisord
# Author: Márk Sági-Kazár (sagikazarmark@gmail.com)
# This script installs Supervisord on Debian/Ubuntu based distributions.
#
# Version: 3.0

# Function definitions

## Echo colored text
e () {
	color=$2
	color="\033[${color:-34}m"
	echo -e "$color$1\033[0m"
}

# Variable definitions

DIR=$(cd `dirname $0` && pwd)
NAME="Supervisord"
VER="3.0"

# Checking root access
if [[ $EUID -ne 0 ]] ; then
	e "This script has to be ran as root!"
	exit 0
fi

e "###### Installing $NAME $VER ######\n"

if [[ -f /usr/local/bin/supervisord ]]; then
	e "WARNING: $NAME is already installed. Do you want to continue? (y/n)" 31
	read -n1 install
	echo
	case "$install" in
		Y|y )
			e "Installing $NAME over the previous version" 31
			;;
		* )
			e "Installation aborted"
			exit 1
			;;
	esac
fi

cd /tmp

e "Cleaning up"
rm -rf supervisor* setuptools*

e "Downloading $NAME $VER and it's dependencies"
wget --quiet https://pypi.python.org/packages/source/s/supervisor/supervisor-3.0.tar.gz > /dev/null
wget --quiet https://pypi.python.org/packages/source/s/setuptools/setuptools-1.0.tar.gz > /dev/null

e "Extracting files"
tar -xvzf supervisor-3.0.tar.gz > /dev/null
tar -xvzf setuptools-1.0.tar.gz > /dev/null

e "Installing Setuptools"
cd setuptools-1.0
python setup.py install > /dev/null

e "Installing $NAME $VER"
cd ../supervisor-3.0
python setup.py install > /dev/null

cd ..

e "Setting up $NAME $VER"
echo_supervisord_conf >> /etc/supervisord.conf
mkdir -p /etc/supervisord.d
mkdir -p /var/run/supervisord

sed -i -e 's/file=\/tmp\/supervisor.sock/file=\/var\/run\/supervisord\/supervisord.sock/' /etc/supervisord.conf
sed -i -e 's/serverurl=unix:\/\/\/tmp\/supervisor.sock/serverurl=unix:\/\/\/var\/run\/supervisord\/supervisord.sock/' /etc/supervisord.conf
sed -i -e 's/pidfile=\/tmp\/supervisord.pid/pidfile=\/var\/run\/supervisord\/supervisord.pid/' /etc/supervisord.conf
sed -i -e 's/logfile=\/tmp\/supervisord.log/logfile=\/var\/log\/supervisord.log/' /etc/supervisord.conf
sed -i -e 's/;\[inet_http_server\]/\[inet_http_server\]/' /etc/supervisord.conf
sed -i -e 's/;port=127.0.0.1:9001/port=*:9001/' /etc/supervisord.conf
sed -i -e 's/;\[include\]/\[include\]/' /etc/supervisord.conf
sed -i -e 's/;files = relative\/directory\/\*.ini/files = supervisord.d\/\*/' /etc/supervisord.conf

[[ -f /usr/bin/supervisord ]] || ln -s /usr/local/bin/supervisord /usr/bin/supervisord
[[ -f /usr/bin/supervisorctl ]] || ln -s /usr/local/bin/supervisorctl /usr/bin/supervisorctl
[[ -f /usr/bin/pidproxy ]] || ln -s /usr/local/bin/pidproxy /usr/bin/pidproxy

e "Deleting setup files"
rm -rf setuptools* supervisor*


#curl https://raw.github.com/gist/176149/88d0d68c4af22a7474ad1d011659ea2d27e35b8d/supervisord.sh > /etc/init.d/supervisord
cp $DIR/supervisord /etc/init.d/supervisord
chmod +x /etc/init.d/supervisord
update-rc.d supervisord defaults

service supervisord stop
service supervisord start

e "\n###### Install done ######"
