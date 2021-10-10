# apt 
apt := DEBIAN_FRONTEND=noninteractive apt -q -y -o DPkg::Options::=--force-confold
aptinst := $(apt) install

# install with back up
inst := install -b -S .bak
# normal files
instf  := $(inst) -m 644
# executables
instx := $(inst) -m 755
# directory
instd := install -d -m 755

this_dir:=$(realpath $(dir $(lastword $(MAKEFILE_LIST))))
bin_dir:= $(realpath $(this_dir)/../bin)
data_dir:=$(realpath $(this_dir)/../data)

ensure_line:=$(bin_dir)/ensure_line
kv_merge:=$(bin_dir)/kv_merge

db:=$(data_dir)/conf.sqlite
nodename?=$(shell $(data_dir)/get_nodename)

define hostvar
$(shell sqlite3 $(db) "select $(1) from hosts where host=\"$(nodename)\"")
endef

.DELETE_ON_ERROR:
