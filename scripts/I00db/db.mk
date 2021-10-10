#
# db.mk --- make a database of hosts and users
# 
include ../common.mk

OK : $(db)

$(db) : $(data_dir)/hosts.csv $(data_dir)/users.csv
	echo -n | sqlite3 -separator , -cmd ".import $(data_dir)/hosts.csv hosts" $(db).tmp
	echo -n | sqlite3 -separator , -cmd ".import $(data_dir)/users.csv users" $(db).tmp
	chmod 0600 $(db).tmp
	mv $(db).tmp $(db)

