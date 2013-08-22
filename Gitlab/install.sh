#!/bin/bash

# Gitlab install script
NAME="Gitlab 5.4"

if [[ "$(id -u)" -ne 0 && "$(lsb_release -si)" -ne "Ubuntu" ]] ; then
	echo -e "\e[1;31mThis script must be run as root!\e[0m"
	exit
elif [[ "$(lsb_release -si)" -ne "Ubuntu" ]] ; then
	apt-get install sudo
fi

# Installing dialog
sudo apt-get install -y --quiet dialog

# Ask database server
DB=$(dialog --stdout --backtitle "Installing $NAME" \
	--title "Choose Database" \
	--radiolist "What database system do you want to use?" 10 34 2 \
	 1 "MySQL" on \
	 2 "PostgreSQL" off)

# Ask webserver
WS=$(dialog --stdout --backtitle "Installing $NAME" \
	--title "Choose Webserver" \
	--radiolist "What webserver do you want to use?" 10 34 2 \
	 1 "Apache" on \
	 2 "Nginx" off)

case "$WS" in
	2)
		WS="nginx"
		ws="nginx"
		;;
	*)
		WS="apache"
		ws="apache2"
		;;
esac

# Ask mail server
MS=$(dialog --stdout --backtitle "Installing $NAME" \
	--title "Choose Mail server type" \
	--radiolist "What mail server do you want to use?" 10 34 2 \
	 1 "Postfix" on \
	 2 "SMTP" off)

case "$MS" in
	2)
		MS="SMTP"
		ms=""
		;;
	*)
		MS="Postfix"
		ms="postfix postfix-policyd-spf-python"
		echo "postfix postfix/mailname string $(hostname -f)" | sudo debconf-set-selections
		echo "postfix postfix/main_mailer_type string 'Internet Site'" | sudo debconf-set-selections
		;;
esac

RUBY=$(dialog --stdout --backtitle "Installing $NAME" \
	--title "Install ruby" \
	--radiolist "Do you want to install ruby (required)?" 10 34 2 \
	 1 "Yes" on \
	 2 "No" off)

case "$RUBY" in
	2)
		RUBY="off"
		;;
	*)
		RUBY="on"
		;;
esac

# Ask MySQL root password
rootpsw () {
	ROOTPSW=$(dialog --stdout --title "MySQL Server" \
		--backtitle "Installing $NAME" \
		--passwordbox "Please enter MySQL root password!" 8 50)
	ROOTPSW2=$(dialog --stdout --title "MySQL Server" \
		--backtitle "Installing $NAME" \
		--passwordbox "Please confirm MySQL root password!" 8 50)

	if [[ $ROOTPSW != $ROOTPSW2 ]]; then
		dialog --title "Error" \
			--backtitle "Installing $NAME" \
			--msgbox "\n Passwords do not match." 6 50
		rootpsw
	fi
	if [[ ${ROOTPSW:-none} = "none" ]]; then
		dialog --title "Error" \
			--backtitle "Installing $NAME" \
			--msgbox "\n No password given." 6 50
		rootpsw
	fi
}

# Ask MySQL Gitlab password
gitlabpsw () {
	GITLABPSW=$(dialog --stdout --title "MySQL Server" \
		--backtitle "Installing $NAME" \
		--passwordbox "Please enter MySQL gitlab user password!" 8 50)
	GITLABPSW2=$(dialog --stdout --title "MySQL Server" \
		--backtitle "Installing $NAME" \
		--passwordbox "Please confirm MySQL gitlab user password!" 8 50)

	if [[ $GITLABPSW != $GITLABPSW2 ]]; then
		dialog --title "Error" \
			--backtitle "Installing $NAME" \
			--msgbox "\n Passwords do not match." 6 50
		gitlabpsw
	fi
	if [[ ${GITLABPSW:-none} = "none" ]]; then
		dialog --title "Error" \
			--backtitle "Installing $NAME" \
			--msgbox "\n No password given." 6 50
		gitlabpsw
	fi
}

# Ask Gitlab hostname
gitlabhost () {
	GITLABHOST=$(dialog --stdout --title "Gitlab Host" \
		--backtitle "Installing $NAME" \
		--inputbox "Please enter Gitlab hostname!" 8 50)

	if [[ ${GITLABHOST:-none} == "none" ]]; then
		dialog --title "Error" \
			--backtitle "Installing $NAME" \
			--msgbox "\n No hostname given." 6 50
		gitlabhost
	fi
}

# Run ask functions

case "$DB" in
	2)
		DB="postgresql"
		db="postgresql-9.1 libpq-dev"
		WITHOUT="mysql"
		;;
	*)
		DB="mysql"
		db="mysql-server mysql-client libmysqlclient-dev"
		WITHOUT="postgres"
		rootpsw
		gitlabpsw
		echo mysql-server mysql-server/root_password password $ROOTPSW | sudo debconf-set-selections
		echo mysql-server mysql-server/root_password_again password $ROOTPSW2 | sudo debconf-set-selections
		;;
esac

gitlabhost

if [[ $WS == "nginx" ]]; then
	gitlabip () {
		GITLABIP=$(dialog --stdout --title "Gitlab IP" \
			--backtitle "Installing $NAME" \
			--inputbox "Please enter Gitlab server IP!" 8 50)

		if [[ ${GITLABIP:-none} == "none" ]]; then
			dialog --title "Error" \
				--backtitle "Installing $NAME" \
				--msgbox "\n No IP given." 6 50
			gitlabip
		fi
	}
	gitlabip
fi

# Install dependencies
sudo apt-get install -y --quiet build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev curl git-core openssh-server redis-server checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev python python2.7 python-docutils $ws $db $ms

# Check python2 available
if [ ! -f /usr/bin/python2 ];
then
	sudo ln -s /usr/bin/python /usr/bin/python2
fi

if [[ $RUBY == "on" ]]; then
	# Install ruby
	if [[ "$(which ruby1.8)" ]]; then
		sudo apt-get remove -y ruby1.8
	fi

	rm -rf /tmp/ruby && mkdir /tmp/ruby && cd /tmp/ruby
	curl --progress http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p392.tar.gz | tar xz
	cd ruby-1.9.3-p392
	./configure
	make
	sudo make install
fi

# Install bundler gem
sudo gem install bundler

# Add git user
sudo adduser --disabled-login --gecos 'GitLab' git

# Enter git dir
cd /home/git

# Clone gitlab shell
sudo -u git -H git clone https://github.com/gitlabhq/gitlab-shell.git

cd gitlab-shell

# switch to right version
git checkout v1.3.0

# Setup gitlab-shell
sudo -u git -H cp config.yml.example config.yml
sudo sed -i -e 's/gitlab_url: "http://localhost/"/gitlab_url: "http://$GITLABHOST/"/' config/gitlab.yml
sudo -u git -H ./bin/install

# We'll install GitLab into home directory of the user "git"
cd /home/git

# Clone GitLab repository
sudo -u git -H git clone https://github.com/gitlabhq/gitlabhq.git gitlab

# Go to gitlab dir
cd /home/git/gitlab

# Checkout to stable release
sudo -u git -H git checkout 5-1-stable

cd /home/git/gitlab

# Copy the example GitLab config
sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml

# Setup Gitlab config
sudo sed -i -e "s/host: localhost/host: $GITLABHOST/" config/gitlab.yml
sudo sed -i -e "s/gitlab@localhost/ gitlab@$GITLABHOST/" config/gitlab.yml
sudo sed -i -e "s/support@localhost/ gitlab@$GITLABHOST/" config/gitlab.yml

# Setup database
case "$DB" in
	"postgresql")
		sudo -u git cp config/database.yml.postgresql config/database.yml
		sudo sed -i -e "s/password:/password: \"$GITLABPSW\"/" config/database.yml

		sudo -u postgres psql -d template1 -c "CREATE USER git WITH PASSWORD '$GITLABPSW';"
		sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;"
		;;
	*)
		sudo -u git cp config/database.yml.mysql config/database.yml
		sudo sed -i -e "s/root/ gitlab/" config/database.yml
		sudo sed -i -e "s/\"secure password\"/\"$GITLABPSW\"/" config/database.yml

		mysql -u root -p$ROOTPSW -e "CREATE USER 'gitlab'@'localhost' IDENTIFIED BY '$GITLABPSW';"
		mysql -u root -p$ROOTPSW -e 'CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;'
		mysql -u root -p$ROOTPSW -e 'GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `gitlabhq_production`.* TO "$NAME"@"localhost";'
		;;
esac


# Make sure GitLab can write to the log/ and tmp/ directories
sudo chown -R git log/
sudo chown -R git tmp/
sudo chmod -R u+rwX  log/
sudo chmod -R u+rwX  tmp/

# Create directory for satellites
sudo -u git -H mkdir /home/git/gitlab-satellites

# Create directories for sockets/pids and make sure GitLab can write to them
sudo -u git -H mkdir tmp/pids/
sudo -u git -H mkdir tmp/sockets/
sudo chmod -R u+rwX  tmp/pids/
sudo chmod -R u+rwX  tmp/sockets/

# Copy the example Puma config
sudo -u git -H cp config/puma.rb.example config/puma.rb

# Install gems
cd /home/git/gitlab

gem install charlock_holmes --version '0.6.9'
sudo -u git -H bundle install --deployment --without development test $WITHOUT

# Run Setup
echo "yes" | sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production

# Install Init script
sudo curl --output /etc/init.d/gitlab https://raw.github.com/gitlabhq/gitlabhq/master/lib/support/init.d/gitlab
sudo chmod +x /etc/init.d/gitlab
sudo update-rc.d gitlab defaults 21

# Check installation
sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production

# Setup webserver
case "$WS" in
	"nginx")
		sudo curl --output /etc/nginx/sites-available/gitlab https://raw.github.com/gitlabhq/gitlabhq/master/lib/support/nginx/gitlab
		sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab

		sudo sed -i -e "s/YOUR_SERVER_IP/ $GITLABIP/" /etc/nginx/sites-enabled/gitlab
		sudo sed -i -e "s/YOUR_SERVER_FQDN/ $GITLABHOST/" /etc/nginx/sites-enabled/gitlab
		sudo service nginx restart
		;;
	*)
		echo "
		<VirtualHost *:80>
			ServerName $GITLABHOST
			ServerAdmin webmaster@$GITLABHOST

			DocumentRoot /home/git/gitlab/public
			ProxyPass /uploads !

			# Uncomment if you want redirect from HTTP to HTTPS
			#RewriteEngine on
			#RewriteCond %{SERVER_PORT} ^80$
			#RewriteRule ^(.*)$ https://%{SERVER_NAME}$1 [L,R]

			ProxyPass / http://127.0.0.1:9292/
			ProxyPassReverse / http://127.0.0.1:9292/
			ProxyPreserveHost On

			CustomLog /var/log/apache2/gitlab/access.log combined
			ErrorLog /var/log/apache2/gitlab/error.log
		</VirtualHost>" | sudo tee /etc/apache2/sites-available/gitlab
		echo "bind 'tcp://127.0.0.1:9292'" | sudo tee -a config/puma.rb
		sudo a2enmod proxy proxy_http rewrite
		sudo a2ensite gitlab
		sudo service apache2 restart
		;;
esac

# Start service
sudo service gitlab start