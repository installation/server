#!/bin/bash

# Script to install Webmin
# Author: Márk Sági-Kazár (sagikazarmark@gmail.com)
# This script installs Webmin on several Linux distributions.
#
# Version: 1.650

# Function definitions

## Echo colored text
e()
{
	color="\033[${2:-34}m"
	echo -e "$color$1\033[0m"
}

# Variable definitions

DIR=$(cd `dirname $0` && pwd)
NAME="Webmin"
VER="1.650"

# Checking root access
if [ $EUID -ne 0 ]; then
	e "This script has to be ran as root!" 31
	exit 1
fi

e "Installing $NAME $VER"

if [ `which apt-get 2> /dev/null` ]; then
	echo "deb http://download.webmin.com/download/repository sarge contrib" | tee /etc/apt/sources.list.d/webmin.list
	echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" | tee -a /etc/apt/sources.list.d/webmin.list

	wget --quiet -O - http://www.webmin.com/jcameron-key.asc | apt-key add -
	apt-get update &> /dev/null
	apt-get install -y -qq webmin &> /dev/null || e "Error installing $NAME $VER!" 31
elif [ `which yum 2> /dev/null` ]; then
	echo "[Webmin]
name=Webmin Distribution Neutral
#baseurl=http://download.webmin.com/download/yum
mirrorlist=http://download.webmin.com/download/yum/mirrorlist
enabled=1" | tee /etc/yum.repos.d/webmin.repo
	wget --quiet -O - http://www.webmin.com/jcameron-key.asc | rpm --import -
	yum -y -q install webmin &> /dev/null || e "Error installing $NAME $VER!" 31
else
	e "Your distribution is not supported!" 31
fi