#
# slapd.mk --- install slapd (slappasswd)
#
# real LDAP config is done in I21ldap
#
include ../common.mk

is_ldap_server:=$(call hvar,is_ldap_server)
ifeq ($(is_ldap_server),1)
  targets := /usr/bin/slappasswd
else
  targets := 
endif

OK : $(targets)

/usr/bin/slappasswd :
	$(aptinst) slapd
	which slappasswd
