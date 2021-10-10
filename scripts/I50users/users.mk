#
# users.mk --- create taulec group and users
#
include ../common.mk

is_ldap_server:=$(call hvar,is_ldap_server)
ifeq ($(is_ldap_server),1)
  targets := make_users
else
  targets := 
endif

# like "abc.example.com"
ldap_domain:=$(call gvar,ldap_domain)
# abc.example.com -> dc=abc,dc=example,dc=com
ldap_domain_dn:=$(shell python3 -c "print(','.join([ 'dc=%s' % x for x in '$(ldap_domain)'.split('.') ]))")
ldap_domain_password:=$(call gvar,ldap_domain_password)

users_csv:=../../data/users.csv
groups_csv:=../../data/groups.csv

OK : $(targets)

make_users :
	bin/make_users_groups.py $(ldap_domain_password) $(ldap_domain_dn) --users $(users_csv) --groups $(groups_csv)
	service sssd restart
