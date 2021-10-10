#
# nfs.mk --- configure nfs server/client
#

include ../common.mk

is_nfs_server:=$(call hvar,is_nfs_server)
fstab:=$(data_dir)/$(call hvar,fstab)
ifeq ($(is_nfs_server),1)
  targets:=nfs_common fstab nfs_server exports
else
  targets:=nfs_common fstab
endif
export nfs_server_hostname = $(call query,select hostname from hosts where is_nfs_server=1 limit 1)
export nfs_clients = $(call query,select PrivateIpAddress from hosts)

OK : $(targets)

nfs_common :
	$(aptinst) nfs-common

nfs_server :
	$(aptinst) nfs-kernel-server

exports : nfs_server work/dir
	(echo -n "/home " ; for c in $(nfs_clients); do echo -n "$$c(rw,async,no_root_squash,no_subtree_check) "; done ; echo "") > work/etc_exports.add
	$(kv_merge) /etc/exports work/etc_exports.add > work/etc_exports
	$(inst) work/etc_exports /etc/exports
	exportfs -a

fstab : nfs_common $(fstab) work/dir
	envsubst < $(fstab) > work/etc_fstab.add
	$(kv_merge) /etc/fstab work/etc_fstab.add > work/etc_fstab
	$(inst) work/etc_fstab /etc/fstab
	mount -a

work/dir :
	mkdir -p $@
