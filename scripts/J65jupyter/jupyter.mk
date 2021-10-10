#
# jupyter.mk --- install jupyter
#
include ../common.mk

subdirs := jupyter c ocaml vpython bash nbgrader sos
targets := $(addsuffix /OK,$(subdirs))

OK : $(targets)

$(targets) : %/OK :
	cd $* && $(MAKE) -f $*.mk
