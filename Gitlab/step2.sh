#!/bin/bash

DIR=$(cd `dirname $0` && pwd)
# If it succeeded without errors you can remove the cloned repo
sudo rm -rf /tmp/gitolite-admin


echo -e "\033[34mCloning and setting up Gitlab\033[0m"

# We'll install GitLab into home directory of the user "gitlab"
cd /home/gitlab

# Clone GitLab repository
sudo -u gitlab -H git clone https://github.com/gitlabhq/gitlabhq.git gitlab

# Go to gitlab dir 
cd /home/gitlab/gitlab

# Checkout to stable release
sudo -u gitlab -H git checkout 4-2-stable

# Copy the example GitLab config
sudo -u gitlab -H cp config/gitlab.yml.example config/gitlab.yml

# Make sure GitLab can write to the log/ and tmp/ directories
sudo chown -R gitlab log/
sudo chown -R gitlab tmp/
sudo chmod -R u+rwX  log/
sudo chmod -R u+rwX  tmp/

# Make directory for satellites
sudo -u gitlab -H mkdir /home/gitlab/gitlab-satellites

# Copy the example Unicorn config
sudo -u gitlab -H cp config/unicorn.rb.example config/unicorn.rb

# Mysql
sudo -u gitlab cp config/database.yml.mysql config/database.yml

#echo -e "\033[34mThis is the end of the second part of the installation. Be sure to check the following config files:\033[0m"
#echo "sudo nano /home/gitlab/gitlab/config/gitlab.yml"
#echo "sudo nano /home/gitlab/gitlab/config/unicorn.rb"
#echo "sudo nano /home/gitlab/gitlab/config/database.yml"

sudo cp $DIR/vhost.conf /etc/apache2/sites-available/gitlab

echo -e "\033[34mWriting config\033[0m"

#Gitlab host
echo -e "\033[34mGitlab host: \033[0m[localhost]"
read host
host=${host:-localhost}
sudo sed -i -e "s/host: localhost/host: $host/" config/gitlab.yml
sudo -u gitlab -H ssh git@$host
sudo sed -i -e "s/\${HOST}/$host/" /etc/apache2/sites-available/gitlab

#Gitlab email
echo -e "\033[34mGitlab email: \033[0m[gitlab@localhost]"
read email_from
email_from=${email_from:-gitlab@localhost}
sudo sed -i -e "s/gitlab@localhost/ $email_from/" config/gitlab.yml

#Support email
echo -e "\033[34mSupport email: \033[0m[gitlab@localhost]"
read support_email
support_email=${support_email:-gitlab@localhost}
sudo sed -i -e "s/support@localhost/ $support_email/" config/gitlab.yml
sudo sed -i -e "s/\${EMAIL}/$support_email/" /etc/apache2/sites-available/gitlab

#Rails server running port
echo -e "\033[34mRails server running port: \033[0m[8000]"
read port
port=${port:-8000}
sudo sed -i -e "s/\#listen 8080/listen $port/" config/unicorn.rb
sudo sed -i -e "s/\${PORT}/$port/" /etc/apache2/sites-available/gitlab

#Database name
echo -e "\033[34mDatabase name: \033[0m[gitlabhq_production]"
read dbname
dbname=${dbname:-gitlabhq_production}
sudo sed -i -e "s/gitlabhq_production/$dbname/" config/database.yml

#Database username
echo -e "\033[34mDatabase username: \033[0m[gitlab]"
read dbuser
dbuser=${dbuser:-gitlab}
sudo sed -i -e "s/root/ $dbuser/" config/database.yml

#Database password
echo -e "\033[34mDatabase password: \033[0m[secure_password]"
read dbpass
dbpass=${dbpass:-secure_password}
sudo sed -i -e "s/\"secure password\"/\"$dbpass\"/" config/database.yml

echo -e "\033[34mSleeping for 2 minutes. Check the following config files\033[0m"
echo "sudo nano /home/gitlab/gitlab/config/gitlab.yml"
echo "sudo nano /home/gitlab/gitlab/config/unicorn.rb"
echo "sudo nano /home/gitlab/gitlab/config/database.yml"
echo "sudo nano /etc/apache2/sites-available/gitlab"
sleep 120


echo -e "\033[34mInstalling gems\033[0m"

sudo gem install charlock_holmes --version '0.6.9'

# For MySQL (note, the option says "without")
sudo -u gitlab -H bundle install --deployment --without development test postgres

# Or for PostgreSQL
#sudo -u gitlab -H bundle install --deployment --without development test mysql

echo -e "\033[34mConfiguring git\033[0m"

echo -e "\033[34mGlobal git user.name config: \033[0m[Gitlab]"
read username
username=${username:-Gitlab}
sudo -u gitlab -H git config --global user.name "$username"

echo -e "\033[34mGlobal git user.name config: \033[0m[gitlab@localhost]" 
read email
email=${email:-gitlab@localhost}
sudo -u gitlab -H git config --global user.email "$email"

echo -e "\033[34mSetup Gitlab hooks\033[0m"
sudo cp ./lib/hooks/post-receive /home/git/.gitolite/hooks/common/post-receive
sudo chown git:git /home/git/.gitolite/hooks/common/post-receive

echo -e "\033[34mSetting up database\033[0m"
sudo -u gitlab -H bundle exec rake gitlab:setup RAILS_ENV=production

echo -e "\033[34mSetup init script\033[0m"
sudo curl --output /etc/init.d/gitlab https://raw.github.com/gitlabhq/gitlab-recipes/4-2-stable/init.d/gitlab
sudo chmod +x /etc/init.d/gitlab
sudo update-rc.d gitlab defaults 21

echo -e "\033[34mStarting service\033[0m"
sudo service gitlab start
sleep 10

echo -e "\033[34mChecking info and setup\033[0m"
sudo -u gitlab -H bundle exec rake gitlab:env:info RAILS_ENV=production

sudo -u gitlab -H bundle exec rake gitlab:check RAILS_ENV=production

echo -e "\033[34mSetting up Apache\033[0m"
sudo mkdir -p /var/log/apache2/gitlab/
sudo a2ensite gitlab
sudo a2enmod proxy proxy_http rewrite
sudo service apache2 reload

echo -e "\033[34mGitlab successfully installed\033[0m"
echo -e "\033[34mAdmin login\033[0m..................admin@local.host"
echo -e "\033[34mAdmin password\033[0m...............5iveL!fe"