#!/bin/bash

sudo apt-get install -y phpmyadmin
sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf.d/phpmyadmin.conf
sudo service apache2 reload