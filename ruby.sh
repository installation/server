#!/bin/bash

echo -e "\033[34mInstalling required components\033[0m"
sudo apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev curl git-core openssh-server redis-server postfix checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev libmysql-ruby libmysqlclient-dev

# Install ruby
echo -e "\033[34mDownloading ruby version 1.9.3\033[0m"
mkdir /tmp/ruby && cd /tmp/ruby
curl --progress http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p327.tar.gz | tar xz
cd ruby-1.9.3-p327
echo -e "\033[34mConfiguring ruby version 1.9.3\033[0m"
./configure
echo -e "\033[34mCompiling ruby version 1.9.3\033[0m"
make
echo -e "\033[34mInstalling ruby version 1.9.3\033[0m"
sudo make install

# Install the Bundler Gem
echo -e "\033[34mInstalling Bundler Gem\033[0m"
sudo gem install bundler