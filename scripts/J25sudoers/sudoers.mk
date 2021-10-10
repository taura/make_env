#
# sudoers.mk --- make taulec group sudoers
#
include ../common.mk

OK : /etc/sudoers.d/sudoers

work/sudoers : $(db) work/dir
	sqlite3 $(db) 'select uid||" ALL=(ALL) NOPASSWD:ALL" from users where sudoer=1' > work/sudoers

/etc/sudoers.d/sudoers : work/sudoers
	$(inst) -m 440 work/sudoers /etc/sudoers.d/sudoers

work/dir :
	mkdir -p $@
