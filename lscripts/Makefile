dirs := $(sort $(wildcard I??*) $(wildcard J??*))
dirs_OK := $(addsuffix /OK,$(dirs))

cur_dir := $(shell pwd)
top_dir := $(realpath $(cur_dir)/..)
bin_dir := $(top_dir)/bin

all : $(dirs_OK)

$(dirs_OK) : %/OK : 
	LC_ALL=C $(MAKE) --warn-undefined-variables -C $* -f $(notdir $(wildcard $*/*.mk))
