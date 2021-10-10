#
# hosts.mk --- generate /etc/hosts
#

include ../common.mk

OK : /etc/hosts

/etc/hosts : $(db)
	sqlite3 -separator " " $(db) 'select PrivateIpAddress,hostname from hosts' > hosts.add
	$(kv_merge) /etc/hosts hosts.add > etc_hosts
	$(instf) etc_hosts /etc/hosts
