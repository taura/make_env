#mode?=user
mode?=root
all : ocaml
include ../jupyter/jupyter.mk

ifeq ($(mode),user)
jupyter_kernelspec_inst := ~/.local/bin/jupyter kernelspec install --user
else
jupyter_kernelspec_inst := sudo jupyter kernelspec install
endif

opam_user:=$(call gvar,opam_user)

ocaml : jupyter
	id $(opam_user) # if this fails, consider setting opam_user= in the make command line (make -f ocaml.mk opam_user=...)
	sudo $(apt) install -y opam m4 pkg-config libzmq3-dev libffi-dev libgmp-dev zlib1g-dev
	sudo -u $(opam_user) ./inst_ocaml_as_user.sh
	$(jupyter_kernelspec_inst) --name ocaml-jupyter ~$(opam_user)/.opam/default/share/jupyter
