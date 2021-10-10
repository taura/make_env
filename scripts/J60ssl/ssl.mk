#
# ssl.mk
#
include ../common.mk

need_ssl:=$(call hvar,need_ssl)
dns_name:=$(call hvar,dns_name)
backup_letsencrypt:=$(wildcard backup/letsencrypt)

# (1) periodically run make -f ssl.mk backup_etc_letsencrypt to make a backup
# (2) explicitly run make -f ssl.mk ssl_config_restore to restore backup

ifeq ($(need_ssl),1)
ifeq ($(backup_letsencrypt),)
  targets := ssl_config_first_time
else
  targets := 
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
	certbot --apache -d $(dns_name) -n --agree-tos --email tau@eidos.ic.i.u-tokyo.ac.jp
	chmod 755 /etc/letsencrypt/live
	chmod 755 /etc/letsencrypt/archive
	chmod 644 /etc/letsencrypt/archive/$(dns_name)/fullchain*.pem
	chmod 644 /etc/letsencrypt/archive/$(dns_name)/privkey*.pem
	rsync -avz /etc/letsencrypt backup/

backup_etc_letsencrypt :
	rsync -avz /etc/letsencrypt backup/

ssl_config_restore : /usr/bin/certbot
	rsync -avz backup/letsencrypt/$(dns_name)/letsencrypt /etc/
	rsync -avz backup/letsencrypt/$(dns_name)/000-default-le-ssl.conf /etc/apache2/sites-available/
	ln -sf /etc/apache2/sites-available/000-default-le-ssl.conf /etc/apache2/sites-enabled/
	service apache2 restart

backup/dir :
	mkdir -p $@
