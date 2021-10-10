#
# hostname.mk --- set the hostname
# 
include ../common.mk

OK : /etc/hostname

hostname:=$(call hvar,hostname)
ifeq ($(hostname),)
hostname:=unknown_hostname
endif
/etc/hostname : $(db)
	hostname $(hostname)
	echo $(hostname) > /etc/hostname
