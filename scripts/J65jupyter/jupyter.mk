#
# jupyter.mk --- install jupyter
#
include ../common.mk

subdirs := jupyter c ocaml bash nbgrader sos
# vpython 
targets := $(addsuffix /OK,$(subdirs))

OK : $(targets)

$(targets) : %/OK :
	cd $* && $(MAKE) -f $*.mk
