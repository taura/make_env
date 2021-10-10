#mode?=user
mode?=root
include ../../common.mk

all : nbgrader

include ../jupyter/jupyter.mk

ifeq ($(mode),user)
jupyter := ~/.local/bin/jupyter
else
jupyter := jupyter
endif

nbgrader : jupyter
ifeq ($(mode),user)
	pip3 install --user nbgrader
#	pip3 install --user --upgrade nbconvert==5.6
	$(jupyter) nbextension install --user --py nbgrader --overwrite
	$(jupyter) nbextension enable --user --py nbgrader
	$(jupyter) serverextension enable --user --py nbgrader
else
	sudo pip3 install nbgrader
	sudo pip3 install --upgrade nbconvert==5.6
	sudo $(jupyter) nbextension install --sys-prefix --py nbgrader --overwrite
	sudo $(jupyter) nbextension enable --sys-prefix --py nbgrader
	sudo $(jupyter) serverextension enable --sys-prefix --py nbgrader
endif
