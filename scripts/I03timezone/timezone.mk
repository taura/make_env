#
# timezone.mk --- set the timezone
# 
include ../common.mk

OK : /etc/sysconfig/clock /etc/localtime

/etc/sysconfig/clock : work/dir
	echo -e 'ZONE="Asia/Tokyo"\nUTC=false' > work/clock
	$(instf) work/clock $@

/etc/localtime : FORCE
	ln -sf -b -S .bak /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

FORCE :

work/dir :
	mkdir -p $@
