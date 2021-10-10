#
# ldap.mk --- configure ldap server/client
#
include ../common.mk

is_ldap_server:=$(call hvar,is_ldap_server)
ifeq ($(is_ldap_server),1)
  targets := ldap_server ldap_client
else
  targets := ldap_client
endif

OK : $(targets)

# like "abc.example.com"
export ldap_domain = $(call gvar,ldap_domain)
# abc.example.com -> dc=abc,dc=example,dc=com
export ldap_domain_dn = $(shell python3 -c "print(','.join([ 'dc=%s' % x for x in '$(ldap_domain)'.split('.') ]))")
# abc.example.com -> abc
export ldap_domain_short = $(shell python3 -c "print('$(ldap_domain)'.split('.')[0])")

export ldap_domain_password = $(call gvar,ldap_domain_password)
export ldap_domain_password_hash = $(shell slappasswd -s $(ldap_domain_password))

export ldap_root_password_hash = $(call gvar,ldap_root_password_hash)
ifeq ($(ldap_root_password_hash),)
export ldap_root_password_hash = $(shell slappasswd -s $(call gvar,ldap_root_password))
endif

#
# common
#
/usr/bin/ldapadd :
	$(aptinst) ldap-utils

#
# server
#
ldap_server : root_pw make_domain

# ldap_root_password_hash
# ldap_domain_dn
root_pw : templates/change_root_pw.ldif /usr/bin/ldapadd work
	envsubst < templates/change_root_pw.ldif > work/change_root_pw.ldif
	ldapadd -Y EXTERNAL -H "ldapi:///" -f work/change_root_pw.ldif

# ldap_domain_password_hash
# ldap_domain_short
# ldap_domain_dn
make_domain : templates/make_domain.ldif /usr/bin/ldapadd work
	envsubst < templates/make_domain.ldif > work/make_domain.ldif
	ldapsearch -Y EXTERNAL -H "ldapi:///" -s base -b $(ldap_domain_dn) > /dev/null || slapadd -l work/make_domain.ldif

#
# client
#

ldap_client : /etc/ldap.conf /etc/ldap.secret remove_use_authtok /etc/sssd/sssd.conf

/usr/sbin/sssd : 
	$(aptinst) sssd libnss-ldap libpam-ldap ldap-utils

# ldap_domain_dn
# ldap_server_hostname
/etc/ldap.conf : templates/ldap.conf /usr/sbin/sssd work
	envsubst < templates/ldap.conf > work/ldap.conf.add
	$(kv_merge) /etc/ldap.conf work/ldap.conf.add > work/etc_ldap.conf
	$(instf) work/etc_ldap.conf /etc/ldap.conf

# ldap_domain_password
/etc/ldap.secret : templates/ldap.secret /usr/sbin/sssd work
	envsubst < templates/ldap.secret > work/ldap.secret
	$(inst) -m 600 work/ldap.secret /etc/ldap.secret

remove_use_authtok : work
	sed -e 's/^password\(.*\)use_authtok\(.*\)$$/password \1 \2/g' /etc/pam.d/common-password > work/common-password
	$(inst) work/common-password /etc/pam.d/common-password

/etc/sssd/sssd.conf : templates/sssd.conf /usr/sbin/sssd work
	envsubst < templates/sssd.conf > work/sssd.conf
	$(inst) -m 600 work/sssd.conf /etc/sssd/sssd.conf
	service sssd restart

work :
	mkdir -p $@

