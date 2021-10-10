#
# aws.mk --- a makefile that brings up and configures
#            a cluster in EC2
#
# usage:
#   make -f aws.mk
#
# description:
#   by running this command, it will automatically bring
#   up a master node and the specified number of compute
#   nodes and inject software configuration into them.
#   it can also be used to add further compute nodes to
#   an already running cluster.
#
#   it is idempotent, in the sense that if you run this
#   command when the cluster is already running, it uses
#   the already running instances.
#
# ----------------------------
# load your config (default : config.mk  or
# you specify the file name by the commnad line
#
#  config=your_config.mk make -f aws.mk
#
# ----------------------------

config ?= config.mk
ifneq (,$(wildcard $(config)))
include $(config)
endif

# ----------------------------
# you should not have to modify anything below
# ----------------------------
# ----------------------------
# check if all variables are defined and correct
# ----------------------------

ifeq (default_key_name,$(key_name))
$(error key_name=default_key_name; you probably did not set key_name. create a key pair in EC2 if you haven not, download the .pem file into this directory, copy config.mk.example to config.mk and set the key_name in it to the name of the key you created)
endif
ifeq (,$(wildcard $(key_name).pem))
$(error you set key_name to $(key_name); make sure you have the file $(key_name).pem)
endif

env_dir := $(shell basename $(env_git) .git)
git_host := $(shell echo $(env_git) | sed -e 's!ssh://!!' -e s/git@// -e 's:/.*::')

# ---------- no need to edit below ----------

key_pem:=$(key_name).pem
ssh:=ssh -A -i $(key_pem)
scp:=scp -i $(key_pem)
rsync:=rsync -az --rsh="ssh -i $(key_pem)"
cloud_sqlite:=../../data/cloud.sqlite
cloud_csv:=$(patsubst %.sqlite,%.csv,$(cloud_sqlite))

apt:=DEBIAN_FRONTEND=noninteractive apt -q -y -o DPkg::Options::=--force-confold
aptinst:=$(apt) install

master_node?=$(master_node_name)
# index of compute nodes 000 001 002 ... n_compute_node-1
compute_nodes_idx:=$(shell seq -f %03.0f 0 $$(($(n_compute_nodes) - 1)))
# compute node names node000 node001 node002 ... 
compute_nodes:=$(addprefix node,$(compute_nodes_idx))

# target strings
# e.g., madb.zapto.org.running
master_node_running:=$(addsuffix .running,$(master_node))
# node000.running node001.running ...
compute_nodes_running:=$(addsuffix .running,$(compute_nodes))

# e.g., madb.zapto.org.ssh
master_node_ssh:=$(addsuffix .ssh,$(master_node))
# node000.ssh node001.ssh ...
compute_nodes_ssh:=$(addsuffix .ssh,$(compute_nodes))

# e.g., madb.zapto.org.configured
master_node_configured:=$(addsuffix .configured,$(master_node))
# node000.configured node001.configured ...
compute_nodes_configured:=$(addsuffix .configured,$(compute_nodes))

# node000.env_dir node001.env_dir ...
compute_nodes_env_dir:=$(addsuffix .env_dir,$(compute_nodes))
# node000.make node001.make ...
compute_nodes_make:=$(addsuffix .make,$(compute_nodes))
# node000.resettings node001.resettings ...
compute_nodes_resettings:=$(addsuffix .resettings,$(compute_nodes))
# node000.make2 node001.make2 ...
compute_nodes_make2:=$(addsuffix .make2,$(compute_nodes))

all_nodes:=$(master_node) $(compute_nodes)
all_nodes_running:=$(master_node_running) $(compute_nodes_running)
all_nodes_ssh:=$(master_node_ssh) $(compute_nodes_ssh)
all_nodes_configured:=$(master_node_configured) $(compute_nodes_configured)

all               : configured
master_running    : $(master_node_running)
running           : $(all_nodes_running)
master_ssh        : $(master_node_ssh)
ssh               : $(all_nodes_ssh)
master_configured : $(master_node_configured)
configured        : $(all_nodes_configured)

addrs :
	mkdir -p $@

# get the master running in ec2
$(master_node_running) : %.running : addrs
# note: get the following volume names from EC2 console
# note: the following device names (/dev/xvd*) can be
# arbitrary, but they must match device names in
# $(env_dir)/scripts/I40fstab/fstab.mk
	# ===== ensure $* is running and attach volumes =====
	./ensure_instance --key-name $(key_name) --instance-type $(master_node_instance_type) --availability-zone $(availability_zone) --image-id $(master_node_image_id) --use_spot $(master_node_use_spot) $(ensure_instance_common_opts) $(ensure_instance_master_node_opts) $* > addrs/$*

# get a compute node running in ec2
$(compute_nodes_running) : %.running : addrs
	# ===== ensure $* is running =====
	./ensure_instance --key-name $(key_name) --instance-type $(compute_node_instance_type) --availability-zone $(availability_zone) --image-id $(compute_node_image_id) --use_spot $(compute_node_use_spot) $(ensure_instance_common_opts) $(ensure_instance_compute_node_opts) $* > addrs/$*

# after the master and compute nodes start running,
# make a database of IP addresses
$(cloud_sqlite) : $(master_node_running) $(compute_nodes_running)
	# ===== make host database into $@ ===== 
	./ensure_instance --key-name $(key_name) $(ensure_instance_common_opts) --dont-run --database $@ $(all_nodes)

$(cloud_csv) : $(cloud_sqlite)
	# ===== make host database into $@ ===== 
	sqlite3 -header -separator , $(cloud_sqlite) "select * from hosts" > $@

# after a node is running, wait until it is root-accessible via ssh.
# a node is initially accessible via 
$(master_node_ssh) $(compute_nodes_ssh) : %.ssh : %.running
	# ===== ensure $* is ssh-accessible ===== 
	for i in $$(seq 1 10); do \
		if $(ssh) -o StrictHostKeyChecking=no -o ConnectTimeout=20 root@$$(cat addrs/$*) echo "$*" | grep "$*" ; then \
			break ; \
		else if $(ssh) -o ConnectTimeout=20 ubuntu@$$(cat addrs/$*) echo "$*" | grep "$*" ; then \
			$(ssh) ubuntu@$$(cat addrs/$*) sudo install -b -S .bak .ssh/authorized_keys /root/.ssh/ ; \
			break ; \
		fi ; fi ; \
		sleep 5 ; \
	done | grep "$*"

# configure a node after all nodes are running
$(compute_nodes_configured) : $(master_node_configured) 
$(all_nodes_configured) : %.configured : %.ssh $(cloud_sqlite) $(cloud_csv)
	# ===== configure $* ===== 
#	$(ssh) root@$$(cat addrs/$*) "dpkg --configure -a --force-confdef"
	- $(ssh) root@$$(cat addrs/$*) "$(apt) update"
#	$(ssh) root@$$(cat addrs/$*) "$(apt) upgrade"
	# ----- configure $* : install make and sqlite3 -----
	$(ssh) root@$$(cat addrs/$*) "$(aptinst) make sqlite3"
	# ----- configure $* : clone configuration scripts -----
	for i in $$(seq 1 10); do \
		if $(ssh) -A root@$$(cat addrs/$*) "export GIT_SSH_COMMAND=\"ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no\"; if [ -e $(env_dir) ]; then cd $(env_dir) ; git pull ; else git clone $(env_git) ; fi" ; then \
			break; \
		fi; \
		$(ssh) root@$$(cat addrs/$*) "echo -e \"Host $(git_host)\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config"; \
	done
	# ----- configure $* : run local setup ----- 
	cd ../../lscripts && make --warn-undefined-variables
	# ----- configure $* : copy host database ----- 
#	$(scp) -r ../../data root@$$(cat addrs/$*):$(env_dir)/
	$(rsync) ../../data root@$$(cat addrs/$*):$(env_dir)/
	# ----- configure $* : do configure ----- 
	$(ssh) root@$$(cat addrs/$*) "cd $(env_dir)/scripts && make --warn-undefined-variables"

