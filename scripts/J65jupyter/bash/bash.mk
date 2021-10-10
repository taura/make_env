#mode?=user
mode?=root
include ../../common.mk

all : bash

include ../jupyter/jupyter.mk

bash : jupyter
ifeq ($(mode),user)
	pip3 install --user bash_kernel
	python3 -m bash_kernel.install
else
	sudo pip3 install bash_kernel
	sudo python3 -m bash_kernel.install
endif
