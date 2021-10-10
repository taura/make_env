this_dir:=$(realpath $(dir $(lastword $(MAKEFILE_LIST))))
bin_dir:= $(realpath $(this_dir)/../bin)
data_dir:=$(realpath $(this_dir)/../data)

ensure_line:=$(bin_dir)/ensure_line
kv_merge:=$(bin_dir)/kv_merge

db:=$(data_dir)/conf.sqlite

