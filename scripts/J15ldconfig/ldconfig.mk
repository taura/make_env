#
# ldconfig.mk --- make /usr/local/{lib,lib64} in library search path
#
include ../common.mk
OK : 
	$(inst) templates/usr_local.conf /etc/ld.so.conf.d/usr_local.conf
	ldconfig


