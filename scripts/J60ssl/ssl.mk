#
# ssl.mk
#
include ../common.mk

need_ssl:=$(call hvar,need_ssl)
hostname:=$(call hvar,hostname)
backup_letsencrypt:=$(wildcard backup/letsencrypt)

ifeq ($(need_ssl),1)
ifeq ($(backup_letsencrypt),)
  targets := ssl_config_first_time
else
  targets := ssl_config_restore
endif
else
  targets :=
endif

pkgs := apache2 libapache2-mod-php

OK : $(targets)

/snap/bin/certbot :
	$(aptinst) snapd
	snap install core
	snap refresh core
	snap install --classic certbot

/usr/bin/certbot : /snap/bin/certbot
	ln -sf /snap/bin/certbot /usr/bin/certbot

ssl_config_first_time : /usr/bin/certbot backup/dir
	certbot --apache -d $(hostname) -n --agree-tos --email tau@eidos.ic.i.u-tokyo.ac.jp
	chmod 755 /etc/letsencrypt/live
	chmod 755 /etc/letsencrypt/archive
	chmod 644 /etc/letsencrypt/archive/$(hostname)/fullchain*.pem
	chmod 644 /etc/letsencrypt/archive/$(hostname)/privkey*.pem
	rsync -avz /etc/letsencrypt bakcup/

ssl_config_restore : /usr/bin/certbot
	rsync -avz backup/letsencrypt/$(hostname)/letsencrypt /etc/
	rsync -avz backup/letsencrypt/$(hostname)/000-default-le-ssl.conf /etc/apache2/sites-available/
	ln -sf /etc/apache2/sites-available/000-default-le-ssl.conf /etc/apache2/sites-enabled/
	service apache2 restart

backup/dir :
	mkdir -p $@
