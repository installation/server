#!/bin/bash

DIR=$(cd `dirname $0` && pwd)

echo -e "\033[34m###### Installing Redmine 2.2.3 ######\033[0m"

echo -e "\033[34mCreating redmine user\033[0m"
sudo adduser \
  --system \
  --shell /bin/sh \
  --gecos 'Redmine' \
  --group \
  --disabled-password \
  --home /usr/share/redmine \
  redmine

echo -e "\033[34mInstalling ImageMagick\033[0m"
sudo apt-get install -y imagemagick libmagick++-dev

echo -e "\033[34mDownloading redmine\033[0m"
mkdir /tmp/redmine && cd /tmp/redmine
wget http://rubyforge.org/frs/download.php/76771/redmine-2.2.3.tar.gz 
tar xvzf redmine-2.2.3.tar.gz
cd redmine-2.2.3/
sudo -u redmine -H cp -R * .[^.]*  /usr/share/redmine/
cd /usr/share/redmine

echo "gem 'unicorn'" | sudo -u redmine -H tee Gemfile.local

echo -e "\033[34mInstalling required gems\033[0m"
sudo bundle install --without development test postgresql sqlite

sudo -u redmine -H cp config/database.yml.example config/database.yml
sudo -u redmine -H rake generate_secret_token

sudo cp $DIR/vhost.conf /etc/apache2/sites-available/redmine
sudo cp $DIR/unicorn.rb /usr/share/redmine/config/
sudo chown redmine:redmine /usr/share/redmine/config/unicorn.rb

echo -e "\033[34mWriting config\033[0m"

#Redmine host
echo -e "\033[34mRedmine host: \033[0m[localhost]"
read host
host=${host:-localhost}
sudo sed -i -e "s/\${HOST}/$host/" /etc/apache2/sites-available/redmine

#Support email
echo -e "\033[34mSupport email: \033[0m[redmine@localhost]"
read support_email
support_email=${support_email:-redmine@localhost}
sudo sed -i -e "s/\${EMAIL}/$support_email/" /etc/apache2/sites-available/redmine

#Rails server running port
echo -e "\033[34mRails server running port: \033[0m[8001]"
read port
port=${port:-8001}
sudo -u redmine -H sed -i -e "s/\#listen 8080/listen $port/" config/unicorn.rb
sudo sed -i -e "s/\${PORT}/$port/" /etc/apache2/sites-available/redmine

#Database name
echo -e "\033[34mDatabase name: \033[0m[redmine]"
read dbname
dbname=${dbname:-redmine}
sudo -u redmine -H sed -i -e "s/database: redmine/database: $dbname/" config/database.yml
sudo -u redmine -H sed -i -e "s/adapter: mysql/adapter: mysql2/" config/database.yml

#Database username
echo -e "\033[34mDatabase username: \033[0m[redmine]"
read dbuser
dbuser=${dbuser:-redmine}
sudo sed -i -e "s/username: root/username: $dbuser/" config/database.yml

#Database password
echo -e "\033[34mDatabase password: \033[0m[secure_password]"
read dbpass
dbpass=${dbpass:-secure_password}
sudo sed -i -e "s/password: \"\"/password: \"$dbpass\"/" config/database.yml

echo -e "\033[34mSleeping for 2 minutes. Check the following config files\033[0m"
echo "sudo nano /usr/share/redmine/config/unicorn.rb"
echo "sudo nano /usr/share/redmine/config/database.yml"
echo "sudo nano /etc/apache2/sites-available/redmine"
sleep 120

echo -e "\033[34mInstalling database\033[0m"
sudo -u redmine -H RAILS_ENV=production rake db:migrate
sudo -u redmine -H RAILS_ENV=production rake redmine:load_default_data

sudo -u redmine -H mkdir -p tmp/ tmp/pdf/ public/plugin_assets/ tmp/sockets/ tmp/pids/
sudo chmod -R 755 files/ public/plugin_assets/
sudo chmod -R u+rwX tmp/
sudo chmod -R 755 log/

echo -e "\033[34mSetup init script\033[0m"
sudo cp $DIR/redmine /etc/init.d/
sudo chmod +x /etc/init.d/redmine
sudo update-rc.d redmine defaults 21

echo -e "\033[34mStarting service\033[0m"
sudo service redmine start
sleep 10

echo -e "\033[34mSetting up Apache\033[0m"
sudo mkdir -p /var/log/apache2/redmine/
sudo a2ensite redmine
sudo a2enmod proxy proxy_http rewrite
sudo service apache2 reload

echo -e "\033[34mRemoving temp files\033[0m"
sudo rm -rf /tmp/redmine

echo -e "\033[34mRedmine successfully installed\033[0m"
echo -e "\033[34mAdmin login\033[0m..................admin"
echo -e "\033[34mAdmin password\033[0m...............admin"