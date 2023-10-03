#
# jupyter.mk --- install jupyter
#
include ../common.mk

# installing nbgrader, jupyterhub, and sos faces version incompatibility issues
# see https://stackoverflow.com/questions/69809832/ipykernel-jupyter-notebook-labs-cannot-import-name-filefind-from-traitlets

#subdirs := jupyter c bash nbgrader sos ocaml 
subdirs := jupyter c bash nbgrader sos
# vpython 
targets := $(addsuffix /OK,$(subdirs))

OK : $(targets)

$(targets) : %/OK :
	cd $* && $(MAKE) -f $*.mk
