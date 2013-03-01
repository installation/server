#!/bin/bash

DIR=$(cd `dirname $0` && pwd)

echo -e "\033[34m###### Installing Gitlab 4.2 ######\033[0m"

# Install the required packages
#echo -e "\033[34mInstalling required components\033[0m"
#sudo apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev curl git-core openssh-server redis-server postfix checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev libmysql-ruby libmysqlclient-dev

# Install Python
sudo apt-get install -y python

# Make sure that Python is 2.5+ (3.x is not supported at the moment)
#python --version
echo -e "\033[34mPython version: \033[0m"
echo `python --version`

# If it's Python 3 you might need to install Python 2 separately
sudo apt-get install -y python2.7

# Make sure you can access Python via python2
# python2 --version

# If you get a "command not found" error create a link to the python binary
if [ ! -f /usr/bin/python2 ];
then
	sudo ln -s /usr/bin/python /usr/bin/python2
fi

# Create user for Git and Gitolite
echo -e "\033[34mCreating git user\033[0m"
sudo adduser \
  --system \
  --shell /bin/sh \
  --gecos 'Git Version Control' \
  --group \
  --disabled-password \
  --home /home/git \
  git

echo -e "\033[34mCreating gitlab user\033[0m"
sudo adduser --disabled-login --gecos 'GitLab' gitlab

# Add it to the git group
echo -e "\033[34mAdding gitlab user to git group\033[0m"
sudo usermod -a -G git gitlab

# Generate the SSH key
echo -e "\033[34mGenerating SSH key\033[0m"
sudo -u gitlab -H ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa

# Clone Gitolite
echo -e "\033[34mCloning and setting up Gitolite\033[0m"
cd /home/git
sudo -u git -H git clone -b gl-v320 https://github.com/gitlabhq/gitolite.git /home/git/gitolite

# Setup Gitolite
# Add Gitolite scripts to $PATH
sudo -u git -H mkdir /home/git/bin
sudo -u git -H sh -c 'printf "%b\n%b\n" "PATH=\$PATH:/home/git/bin" "export PATH" >> /home/git/.profile'
sudo -u git -H sh -c 'gitolite/install -ln /home/git/bin'

# Copy the gitlab user's (public) SSH key ...
sudo cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
sudo chmod 0444 /home/git/gitlab.pub

# ... and use it as the admin key for the Gitolite setup
sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; gitolite setup -pk /home/git/gitlab.pub"

# Make sure the Gitolite config dir is owned by git
sudo chmod 750 /home/git/.gitolite/
sudo chown -R git:git /home/git/.gitolite/

# Make sure the repositories dir is owned by git and it stays that way
sudo chmod -R ug+rwX,o-rwx /home/git/repositories/
sudo chown -R git:git /home/git/repositories/
sudo -u git -H find /home/git/repositories -type d -print0 | sudo xargs -0 chmod g+s

sudo -u gitlab -H ssh git@localhost

# Clone the admin repo so SSH adds localhost to known_hosts ...
# ... and to be sure your users have access to Gitolite
sudo -u gitlab -H git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin

echo -e "\033[34mThis is the end of the first part of the installation. If everything went ok, go to step two.\033[0m"