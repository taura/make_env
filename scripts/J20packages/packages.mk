#
# packages.mk --- install packages
#
include ../common.mk

pkgs := 
pkgs += libsqlite3-dev
pkgs += sqlite3
pkgs += python3-pip
pkgs += gcc
pkgs += g++
pkgs += gdb
#pkgs += clang
#pkgs += clang-3.8
#pkgs += clang-3.8-doc
#pkgs += clang-3.8-examples
#pkgs += lldb-3.8
#pkgs += libtbb-dev
pkgs += lv
pkgs += numactl
pkgs += unzip
pkgs += subversion
pkgs += git
pkgs += opam
pkgs += camlp4-extra
pkgs += libcairo2-dev
pkgs += emacs
pkgs += gcc-doc
pkgs += gdb-doc
pkgs += gnuplot

OK : $(pkgs)

$(pkgs) : % : do_install

do_install :
	$(aptinst) $(pkgs)
