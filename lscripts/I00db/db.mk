#
# db.mk --- make a database of hosts and users
# 
include ../common.mk

OK : $(db)

$(db) : $(data_dir)/hosts.csv $(data_dir)/users.csv $(data_dir)/cloud.csv
	echo -n | sqlite3 -separator , -cmd ".import $(data_dir)/cloud.csv cloud" $(db).tmp
	echo -n | sqlite3 -separator , -cmd ".import $(data_dir)/hosts.csv hosts_" $(db).tmp
	echo -n | sqlite3 -separator , -cmd ".import $(data_dir)/users.csv users" $(db).tmp
	sqlite3 $(db).tmp "create table hosts as select * from cloud natural join hosts_"
	chmod 0600 $(db).tmp
	mv $(db).tmp $(db)

