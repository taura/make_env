#
# cgroup2.mk
#
include ../common.mk

OK : /boot/grub/grub.cfg /usr/local/bin/cg_mem_limit

/boot/grub/grub.cfg : /etc/default/grub.d/50-cloudimg-settings.cfg
	update-grub
	echo "*********** cgroup2 will be effective after you reboot ***********"

/etc/default/grub.d/50-cloudimg-settings.cfg : templates/50-cloudimg-settings.cfg
	$(inst) -m 644 templates/50-cloudimg-settings.cfg /etc/default/grub.d/

/usr/local/bin/cg_mem_limit : src/cg_mem_limit.py /usr/local/bin/write_to_cgroup_procs work/dir
	sed s:WRITE_TO_CGROUP_PROCS:/usr/local/bin/write_to_cgroup_procs:g src/cg_mem_limit.py > work/cg_mem_limit
	chmod +x work/cg_mem_limit
	sudo install work/cg_mem_limit $@
	sudo chown root:root $@

/usr/local/bin/write_to_cgroup_procs : /usr/local/bin/% : src/%.c
	gcc -Wall -Wextra -O3 -o $@ $<
	sudo chown root:root $@
	sudo chmod +s $@

work/dir :
	mkdir -p $@
