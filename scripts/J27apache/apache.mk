#
# apache.mk 
#
include ../common.mk
targets := apache_config

pkgs := apache2 libapache2-mod-php

OK : $(targets)

# install prerequisites
packages : 
	$(aptinst) $(pkgs)

# configure apache
apache_config : packages
# enable php under public_html
	sed -i "s/php_admin_flag engine Off/php_admin_flag engine On/g" /etc/apache2/mods-available/php7.?.conf
# required to add Options -Indexes in the public_html.
# two spaces between Limit and Indexes below prevent repeated application
# of this substitution
	sed -i "s/AllowOverride FileInfo AuthConfig Limit Indexes/AllowOverride FileInfo AuthConfig Limit  Indexes Options/g" /etc/apache2/mods-available/userdir.conf
# without the following two lines apache2 might fail to restart with:
# job for apache2.service failed because the control process exited with error code. See "systemctl status apache2.service" and "journalctl -xe" for details.
# see http://askubuntu.com/questions/760787/php-rendered-as-text-after-ubuntu-16-04-upgrade
	a2dismod mpm_event
	a2enmod mpm_prefork
	a2enmod userdir
	a2enmod $(shell basename /etc/apache2/mods-available/php7.?.conf .conf)
	a2enmod ssl
	a2enmod headers
	service apache2 restart

