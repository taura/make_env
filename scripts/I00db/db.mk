#
# db.mk --- make a database of hosts and users
# 
include ../common.mk

OK : $(hdb) $(udb)

$(hdb) : $(data_dir)/hosts.csv
	echo -n | sqlite3 -separator , -cmd ".import $(data_dir)/hosts.csv hosts" $(hdb).tmp
	chmod 0600 $(hdb).tmp
	mv $(hdb).tmp $(hdb)

$(udb) : $(data_dir)/users.csv
	echo -n | sqlite3 -separator , -cmd ".import $(data_dir)/users.csv users" $(udb).tmp
	chmod 0600 $(udb).tmp
	mv $(udb).tmp $(udb)
