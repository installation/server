#!/bin/bash

DIR=$(cd `dirname $0` && pwd)

echo -e "\033[34m###### Uninstalling Redmine 2.2.3 ######\033[0m"

echo -e "\033[34mRemoving user\033[0m"
sudo deluser redmine
echo -e "\033[34mRemoving usergroup\033[0m"
sudo delgroup redmine
echo -e "\033[34mRemoving home directory\033[0m"
sudo rm -rf /usr/share/redmine
echo -e "\033[34mRemoving temp files\033[0m"
sudo rm -rf /tmp/redmine
echo -e "\033[34mRemoving startup files\033[0m"
sudo update-rc.d -f redmine remove
sudo rm /etc/init.d/redmine

echo -e "\033[34mDone. Empty the database manually\033[0m"