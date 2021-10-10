all : vpython

include ../jupyter/jupyter.mk

#mode?=user
mode?=root

vpython : jupyter
	sudo rm -rf vpython-jupyter
	git clone https://gitlab.eidos.ic.i.u-tokyo.ac.jp/thiguchi/vpython-jupyter
ifeq ($(mode),user)
	pip3 install --user 'jupyter-client>=6.1.5'
	cd vpython-jupyter &&      python3 setup.py install --user
else
	sudo pip3 install 'jupyter-client>=6.1.5'
	cd vpython-jupyter && sudo python3 setup.py install
# see below for the reason for this
	sudo rsync -avz $$(dirname $$(python3 -c 'import vpython; print(vpython.__file__)'))/vpython_data /usr/local/share/jupyter/lab/static/
endif

# when vpython is installed in the syste directory for everybody,
# then the following error happens when a user first uses a graphics
# function (e.g., sphere())
#
# PermissionError: [Errno 13] Permission denied: '/usr/local/share/jupyter/lab/static/vpython_data/rough_texture.jpg'
#
# this happens because vpython tries to install some static images
# (such as textures) into the notebook directory when it finds
# they have not been installed (or the source is newer than dest).
# but the destination is writable only by root.
#
# specifically, the source seems something like
# /usr/local/lib/python3.8/dist-packages/vpython-7.5.0+9.g8888e89-py3.8.egg/vpython/vpython_data
# and the destination is
# /usr/local/share/jupyter/lab/static/vpython_data
#
# the above rsync commands make sure that the former becomes newer than the latter
#
# a smarter way is to invoke the installation as a root, but
# I don't know how to do it in the command line (without a browser)
#
# I initially thought the following works the problem around, but it doesn't
#
# mkdir -p /usr/local/share/jupyter/lab/static/vpython_data -m 777

