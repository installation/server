#!/bin/bash

# Script to install Redmine 2.3.2
# Author: Márk Sági-Kazár (sagikazarmark@gmail.com)
# This script installs Redmine on Debian/Ubuntu based distributions.
#
# Version: 2.3.2

DIR=$(cd `dirname $0` && pwd)
NAME="Redmine"
VER="2.3.2"

# Function definitions

# MySQL root password
rootpsw () {
	ROOTPSW=$(dialog --stdout --title "MySQL Server" \
		--backtitle "Installing $NAME $VER" \
		--passwordbox "Please enter MySQL root password!" 8 50)
	ROOTPSW2=$(dialog --stdout --title "MySQL Server" \
		--backtitle "Installing $NAME $VER" \
		--passwordbox "Please confirm MySQL root password!" 8 50)

	if [[ $ROOTPSW != $ROOTPSW2 ]]; then
		dialog --title "Error" \
			--backtitle "Installing $NAME $VER" \
			--msgbox "\n Passwords do not match." 6 50
		rootpsw
	fi
	if [[ -z ROOTPSW ]]; then
		dialog --title "Error" \
			--backtitle "Installing $NAME $VER" \
			--msgbox "\n No password given." 6 50
		rootpsw
	fi
}

# MySQL user password
userpsw () {
	USERPSW=$(dialog --stdout --title "MySQL Server" \
		--backtitle "Installing $NAME $VER" \
		--passwordbox "Please enter MySQL user password!" 8 50)
	USERPSW2=$(dialog --stdout --title "MySQL Server" \
		--backtitle "Installing $NAME $VER" \
		--passwordbox "Please confirm MySQL user password!" 8 50)

	if [[ $USERPSW != $USERPSW2 ]]; then
		dialog --title "Error" \
			--backtitle "Installing $NAME $VER" \
			--msgbox "\n Passwords do not match." 6 50
		userpsw
	fi
	if [[ -z $USERPSW ]]; then
		dialog --title "Error" \
			--backtitle "Installing $NAME $VER" \
			--msgbox "\n No password given." 6 50
		userpsw
	fi
}

# Hostname
host () {
	HOST=$(dialog --stdout --title "Hostname" \
		--backtitle "Installing $NAME $VER" \
		--inputbox "Please enter hostname!" 8 50)

	if [[ -z $HOST ]]; then
		dialog --title "Error" \
			--backtitle "Installing $NAME $VER" \
			--msgbox "\n No hostname given." 6 50
		host
	fi
}

# Rails server port
port () {
	PORT=$(dialog --stdout --title "Rails server port" \
		--backtitle "Installing $NAME $VER" \
		--inputbox "Please enter port number for Rails server!" 8 50 '9293')

	if [[ -z $PORT ]]; then
		dialog --title "Error" \
			--backtitle "Installing $NAME $VER" \
			--msgbox "\n No port number given." 6 50
		port
	fi
}

# Echo colored
e () {
	echo -e "\033[34m$1\033[0m"
}

# Installing dialog
sudo apt-get install -y dialog --quiet

# Install with defaults
EASY=$(dialog --stdout --backtitle "Installing $NAME $VER" \
	--title "Easy install" \
	--radiolist "Do you want to install $NAME $VER with default preferences?" 10 34 2 \
	 1 "Yes" on \
	 2 "No" off )

case "$EASY" in
	1)
		RS="unicorn"

		DB="mysql"
		db="mysql-server mysql-client libmysqlclient-dev"
		WITHOUT="postgres"
		rootpsw
		userpsw
		echo mysql-server mysql-server/root_password password $ROOTPSW | sudo debconf-set-selections
		echo mysql-server mysql-server/root_password_again password $ROOTPSW2 | sudo debconf-set-selections

		WS="apache"
		ws="apache2"
		host
		port

		if [[ -z `which ruby` ]]; then
			RUBY="on"
		else
			RUBY="off"
		fi
		;;
	*)

		# Rails server
		RS=$(dialog --stdout --backtitle "Installing $NAME $VER" \
			--title "Choose Rails server" \
			--radiolist "Which Rails server do you want to use?" 10 34 2 \
			 1 "Unicorn" off \
			 2 "Puma" on )

		case "$RS" in
			2)
				RS="puma"
				;;
			*)
				RS="unicorn"
				;;
		esac

		# Database server
		DB=$(dialog --stdout --backtitle "Installing $NAME $VER" \
			--title "Choose Database" \
			--radiolist "Which database server do you want to use?" 10 34 2 \
			 1 "MySQL" on \
			 2 "PostgreSQL" off )

		case "$DB" in
			2)
				DB="postgresql"
				db="postgresql-9.1 libpq-dev"
				WITHOUT="mysql"
				userpsw
				;;
			*)
				DB="mysql"
				db="mysql-server mysql-client libmysqlclient-dev"
				WITHOUT="postgres"
				rootpsw
				userpsw
				echo mysql-server mysql-server/root_password password $ROOTPSW | sudo debconf-set-selections
				echo mysql-server mysql-server/root_password_again password $ROOTPSW2 | sudo debconf-set-selections
				;;
		esac

		# Webserver
		WS=$(dialog --stdout --backtitle "Installing $NAME $VER" \
			--title "Choose Webserver" \
			--radiolist "Which webserver do you want to use?" 10 34 2 \
			 1 "Apache" on \
			 2 "Nginx" off )

		case "$WS" in
			2)
				WS="nginx"
				ws="nginx"
				;;
			*)
				WS="apache"
				ws="apache2"
				port
				;;
		esac

		host

		# Ruby
		RUBY=$(dialog --stdout --backtitle "Installing $NAME $VER" \
			--title "Install ruby" \
			--radiolist "Do you want to install ruby (required)?" 10 34 2 \
			 1 "Yes" on \
			 2 "No" off )

		case "$RUBY" in
			2)
				RUBY="off"
				;;
			*)
				RUBY="on"
				;;
		esac
		;;
esac

# Installing dependencies
e "Installing dependencies"

sudo apt-get install -y --quiet build-essential make zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev curl git-core openssh-server redis-server checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev python python2.7 imagemagick libmagick++-dev $ws $db

# Installing Ruby 2.0.0
if [[ $RUBY == "on" ]]; then
	e "Installing Ruby 2.0.0"

	rm -rf /tmp/ruby && mkdir /tmp/ruby && cd /tmp/ruby
	curl --progress ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p247.tar.gz | tar xz
	cd ruby-2.0.0-p247
	./configure
	make
	sudo make install
	rm -rf /tmp/ruby
fi

# Adding user
e "Adding $NAME user"

sudo adduser --disabled-login --gecos 'Redmine' --home /usr/share/redmine redmine

# Downloading files
e "Downloading $NAME $VER"

cd /tmp
rm -rf redmine-2.3.2/
wget http://rubyforge.org/frs/download.php/77023/redmine-2.3.2.tar.gz
tar xvzf redmine-2.3.2.tar.gz
sudo mv redmine-2.3.2/* /usr/share/redmine/
sudo chown redmine.redmine -R /usr/share/redmine/
rm -rf /tmp/redmine-2.3.2

# Installing database
e "Installing database"

case "$DB" in
	"postgresql")
		echo "
production:
  adapter: postgresql
  database: redmine
  host: localhost
  username: redmine
  password: \"$USERPSW\"
  encoding: utf8" | sudo -u redmine -H tee config/database.yml

		sudo -u postgres psql -d template1 -c "CREATE ROLE redmine LOGIN ENCRYPTED PASSWORD '$USERPSW' NOINHERIT VALID UNTIL 'infinity';"
		sudo -u postgres psql -d template1 -c "CREATE DATABASE redmine WITH ENCODING='UTF8' OWNER=redmine;"
		;;
	*)
		echo "
production:
  adapter: mysql2
  database: redmine
  host: localhost
  username: redmine
  password: \"$USERPSW\"
  encoding: utf8" | sudo -u redmine -H tee config/database.yml

		mysql -u root -p$ROOTPSW -e "CREATE USER 'redmine'@'localhost' IDENTIFIED BY '$USERPSW';"
		mysql -u root -p$ROOTPSW -e 'CREATE DATABASE IF NOT EXISTS `redmine` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;'
		mysql -u root -p$ROOTPSW -e 'GRANT ALL PRIVILEGES ON redmine.* TO "redmine"@"localhost";'
		;;
esac


cd /usr/share/redmine

# Setting up Rails server
e "Setting up Rails server"

echo "gem '$RS'" | sudo -u redmine -H tee Gemfile.local
sudo cp $DIR/$RS.rb /usr/share/redmine/config/
sudo chown redmine:redmine /usr/share/redmine/config/$RS.rb

# Installing required gems
e "Installing required gems"

sudo gem install bundler
sudo bundle install --without development test sqlite $WITHOUT

# Setting up
e "Setting up $NAME $VER"

sudo -u redmine -H rake generate_secret_token

sudo -u redmine -H mkdir -p tmp/ tmp/pdf/ public/plugin_assets/ tmp/sockets/ tmp/pids/
sudo chmod -R 755 files/ public/plugin_assets/
sudo chmod -R u+rwX tmp/
sudo chmod -R 755 log/

sudo -u redmine -H RAILS_ENV=production rake db:migrate
sudo -u redmine -H RAILS_ENV=production rake redmine:load_default_data

# Installing init script
e "Installing init script"

sudo cp $DIR/redmine.$RS /etc/init.d/redmine
sudo chmod +x /etc/init.d/redmine
sudo update-rc.d redmine defaults 21

# Setting up webserver
e "Setting up webserver"

case "$WS" in
	"nginx")
		echo "
# REDMINE
# Maintainer: @sagikazarmark
# App Version: $VER

upstream redmine {
  server unix:/usr/share/redmine/tmp/sockets/redmine.socket;
}

server {
  listen *:80 default_server;
  server_name $HOST;
  server_tokens off;
  root /usr/share/redmine/public;
  access_log  /var/log/nginx/redmine_access.log;
  error_log   /var/log/nginx/redmine_error.log;

  location / {
    try_files $uri $uri/index.html $uri.html @redmine;
  }

  location @redmine {
    proxy_read_timeout 300;
    proxy_connect_timeout 300;
    proxy_redirect     off;

    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   Host              $http_host;
    proxy_set_header   X-Real-IP         $remote_addr;

    proxy_pass http://redmine;
  }
}" | sudo tee /etc/nginx/sites-available/redmine
		sudo ln -s /etc/nginx/sites-available/redmine /etc/nginx/sites-enabled/redmine

		sudo service nginx restart
		;;
	*)
		echo "
<VirtualHost *:80>
	ServerName $HOST
	ServerAdmin webmaster@$HOST

	DocumentRoot /usr/share/redmine/public
	ProxyPass /uploads !

	# Uncomment if you want redirect from HTTP to HTTPS
	#RewriteEngine on
	#RewriteCond %{SERVER_PORT} ^80$
	#RewriteRule ^(.*)$ https://%{SERVER_NAME}$1 [L,R]

	ProxyPass / http://127.0.0.1:$PORT/
	ProxyPassReverse / http://127.0.0.1:$PORT/
	ProxyPreserveHost On

	CustomLog /var/log/apache2/redmine/access.log combined
	ErrorLog /var/log/apache2/redmine/error.log
</VirtualHost>" | sudo tee /etc/apache2/sites-available/redmine

		case "$RS" in
			"unicorn")
				echo "listen \"127.0.0.1:$PORT\"" | sudo tee -a config/unicorn.rb
				;;
			*)
				echo "bind 'tcp://127.0.0.1:$PORT'" | sudo tee -a config/puma.rb
				;;
		esac

		sudo a2enmod proxy proxy_http rewrite
		sudo a2ensite redmine
		sudo mkdir -p /var/log/apache2/redmine
		sudo service apache2 restart
		;;
esac

# Starting service
e "Starting service"
sudo service redmine start
sleep 10

e "Redmine successfully installed"
e "Host.........................$HOST"
e "Admin login..................admin"
e "Admin password...............admin"