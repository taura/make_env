#!/bin/bash
set -e
opam init --yes
opam install --yes jupyter
opam install --yes jupyter-archimedes
opam install --yes menhir
~/.opam/default/bin/ocaml-jupyter-opam-genspec
sed --in-place=.bak -e s:'eval $(opam config env --switch=default --shell=sh)':". /home/$(whoami)/.opam/opam-init/init.sh":g ~/.opam/default/share/jupyter/kernel.json

#	opam install iocaml-kernel
