#
# jupyter.mk --- install jupyter
#
include ../common.mk

#subdirs := jupyter c bash nbgrader sos ocaml 
subdirs := jupyter c bash nbgrader sos
# vpython 
targets := $(addsuffix /OK,$(subdirs))

OK : $(targets)

$(targets) : %/OK :
	cd $* && $(MAKE) -f $*.mk
