ec2
================

This directory contains files necessary to set up madb cluster in Amazon EC2.

main files
================

 * aws.mk          --- toplevel make file to launch an Amazon EC2 cluster
 * ensure_instance --- a small python script to interact with EC2 

prerequisites
================
you must have the following.  if you don't follow the instructions that follow.

 * an AWS account (an Amazon account or an IAM user account)
 * python3
 * boto3 (python module; see http://boto3.readthedocs.io/en/latest/index.html)
```
pip3 install --user boto3
```
 * make, ssh, scp

set up before use
================

configure boto3 credentials and region
--------------

 * follow http://boto3.readthedocs.io/en/latest/guide/quickstart.html#configuration to configure boto3 so that:
  * boto3 uses the Oregon (us-west-2) region
  * boto3 knows your access key and secret access key

to make sure things are set up correctly, check if the following works with Python3
```
$ python3
>>> import boto3
>>> ec2 = boto3.client("ec2")
>>> ec2.describe_instances()
```

NOTE: make sure you use the right AWS region and availability zone; we have been putting everything in us-west-2b availability zone in us-west-2 (oregon) region. make sure you always see this region in the web console, for which you specify the region on the upper right corner of the dashboard. choose "US West (Oregon)" there. along the same line, also make sure you put instances and ebs volumes in us-west-2b availability zone (ensure_instance uses this zone by default).

get the key (.pem) file
--------------

from EC2 console, create key pair and save the private key (.pem) file. it is recommended to name your key with your name + the region name (e.g., tau-us-west-2-oregon-key).  you will get the private key file (e.g., tau-us-west-2-oregon-key.pem).

save it into the directory that has this (README.md) file.

check if ensure_instance works correctly
--------------

once you set up boto3 and get a key pair, check if ensure_instance, which internally uses boto3, works correctly.

 * the following searches for an instance of the name "hoge" in the specified region, which will find nothing (unless you happened to run an instance of the name "hoge"). it will at least check if your boto3 setting is correct.
```
$ ./ensure_instance --dont-run hoge
current state of hoge : not_found
```
 * the following will bring up a new instance and give it a tag "hogehoge".  

run this command (with KEY_NAME replaced with the name of your key).
```
(put your .pem file in the current directory; assume it is YOUR_KEY.pem)
$ ./ensure_instance --key-name YOUR_KEY hogehoge
current state of hogehoge : not_found
running a new instance hogehoge
 instance_id : i-0df2dd447e209f72f, attach the name hogehoge
wait for i-0df2dd447e209f72f to be running
 0.787463 : i-0df2dd447e209f72f pending
 1.605735 : i-0df2dd447e209f72f pending

    ...  

 16.878393 : i-0df2dd447e209f72f pending
 17.624979 : i-0df2dd447e209f72f running
34.209.134.62
```

this command runs an instance and attaches it a name "hogehoge".
at the end of the command it will show its public IP address.
see the instance is running in the EC2 console.

you should be able to ssh to the instance by the following command.
```
$ ssh -i YOUR_KEY.pem ubuntu@34.209.134.62
```
(replace the IP address with what ensure_instance printed)

one important feature of ensure_instance command is that when
it is invoked when an instance of the specified is already running,
it does nothing. to see this run the same command again:

```
$ ./ensure_instance --key-name YOUR_KEY hogehoge
current state of hogehoge : running
wait for i-0df2dd447e209f72f to be running
 0.850339 : i-0df2dd447e209f72f running
34.209.134.62
```

to stop the instance, ssh to the instance and run
```
$ ssh -i YOUR_KEY.pem ubuntu@34.209.134.62
instance_terminal$ sudo shutdown -h now
```

check the EC2 console to see that it is now in "stopped" state.

note that in the "stopped" state, the contents of the file 
system still remain. when you bring up the same instance again,
it will have a different IP address but the same contents 
in the file system.

to completely evacuate the instance, right click the instance
on the EC2 console and change the instance state to "terminate".

running an instance is only the first step toward a working
environment.

aws.mk --- a makefile to bring up and configure multiple instances
================

aws.mk is a makefile built around ensure_instance to bring up
multiple instances and configure them. to see what it does,
first try to dry-run it.
```
$ make -f aws.mk -n
aws.mk:139: *** key_name=default_key_name; you probably did not set key_name. create a key pair in EC2 if you haven not, download the .pem file into this directory, copy config.mk.example to config.mk and set the key_name in it to the name of the key you created.  Stop.
```

this error happens as you probably has not specified the key name you use to access the instance. there are several ways to specify it.

 * run make with key_name=xxxxx option
```
$ make -f aws.mk key_name=YOUR_KEY -n
```
 * copy the config.mk.example file to config.mk and write key_name=YOUR_KEY in the file.

after this set up, make -f aws.mk -n will show you what will happen.

```
$ make -f aws.mk -n
mkdir -p addrs
# ===== ensure madb.zapto.org is running and attach volumes =====
./ensure_instance --key-name tau-us-west-2-oregon-key  --instance-type m5.2xlarge --volume vol-00770c09fd604ea65:/dev/sdf --volume vol-0e9f80c10ec5f7676:/dev/sdg --volume vol-0e83222ccdda234d0:/dev/sdh madb.zapto.org > addrs/madb.zapto.org
# ===== ensure madb.zapto.org is ssh-accessible ===== 
for i in $(seq 1 10); do \
	if ssh -i tau-us-west-2-oregon-key.pem -o ConnectTimeout=5 root@$(cat addrs/madb.zapto.org) echo "madb.zapto.org" | grep "madb.zapto.org" ; then \
		break ; \
	else if ssh -i tau-us-west-2-oregon-key.pem -o ConnectTimeout=5 ubuntu@$(cat addrs/madb.zapto.org) echo "madb.zapto.org" | grep "madb.zapto.org" ; then \
		ssh -i tau-us-west-2-oregon-key.pem ubuntu@$(cat addrs/madb.zapto.org) sudo install -b -S .bak .ssh/authorized_keys /root/.ssh/ ; \
		break ; \
	fi ; fi ; \
	sleep 5 ; \
done
# ===== ensure node000 is running =====
./ensure_instance --key-name tau-us-west-2-oregon-key  --instance-type m5.2xlarge node000 > addrs/node000
# ===== make host database into hosts.sqlite ===== 
./ensure_instance --key-name tau-us-west-2-oregon-key  --dont-run --database hosts.sqlite madb.zapto.org node000
# ===== configure madb.zapto.org ===== 
# ----- configure madb.zapto.org : install make and sqlite3 -----
ssh -i tau-us-west-2-oregon-key.pem root@$(cat addrs/madb.zapto.org) "DEBIAN_FRONTEND=noninteractive apt-get -q -y -o DPkg::Options::=--force-confold install make sqlite3"
# ----- configure madb.zapto.org : clone configuration scripts -----
ssh -i tau-us-west-2-oregon-key.pem root@$(cat addrs/madb.zapto.org) "if [ -e madb_env ]; then cd madb_env ; git pull ; else git clone https://gitlab.eidos.ic.i.u-tokyo.ac.jp/tau/madb_env.git ; fi"
# ----- configure madb.zapto.org : copy host database ----- 
scp -i tau-us-west-2-oregon-key.pem hosts.sqlite root@$(cat addrs/madb.zapto.org):madb_env/scripts/
# ----- configure madb.zapto.org : do configure ----- 
ssh -i tau-us-west-2-oregon-key.pem root@$(cat addrs/madb.zapto.org) "cd madb_env/scripts && make --warn-undefined-variables"
# ===== ensure node000 is ssh-accessible ===== 
for i in $(seq 1 10); do \
	if ssh -i tau-us-west-2-oregon-key.pem -o ConnectTimeout=5 root@$(cat addrs/node000) echo "node000" | grep "node000" ; then \
		break ; \
	else if ssh -i tau-us-west-2-oregon-key.pem -o ConnectTimeout=5 ubuntu@$(cat addrs/node000) echo "node000" | grep "node000" ; then \
		ssh -i tau-us-west-2-oregon-key.pem ubuntu@$(cat addrs/node000) sudo install -b -S .bak .ssh/authorized_keys /root/.ssh/ ; \
		break ; \
	fi ; fi ; \
	sleep 5 ; \
done
# ===== configure node000 ===== 
# ----- configure node000 : install make and sqlite3 -----
ssh -i tau-us-west-2-oregon-key.pem root@$(cat addrs/node000) "DEBIAN_FRONTEND=noninteractive apt-get -q -y -o DPkg::Options::=--force-confold install make sqlite3"
# ----- configure node000 : clone configuration scripts -----
ssh -i tau-us-west-2-oregon-key.pem root@$(cat addrs/node000) "if [ -e madb_env ]; then cd madb_env ; git pull ; else git clone https://gitlab.eidos.ic.i.u-tokyo.ac.jp/tau/madb_env.git ; fi"
# ----- configure node000 : copy host database ----- 
scp -i tau-us-west-2-oregon-key.pem hosts.sqlite root@$(cat addrs/node000):madb_env/scripts/
# ----- configure node000 : do configure ----- 
ssh -i tau-us-west-2-oregon-key.pem root@$(cat addrs/node000) "cd madb_env/scripts && make --warn-undefined-variables"
```

you may be overwhelmed by the output, but it is worth taking a look at it to feel that what happen are actually simple. it will do the following.

 * run a master node and a compute node (using ensure_instance). 
 * wait for them to be ssh-accessible
 * make it ssh-accessible as root. ubuntu images do not allow remote login as root by default. they allow remote login as ubuntu user. we fix this by copying /home/ubuntu/.ssh/authorized_keys into /root/.ssh/authorized_keys.  this is necessary because /home/ubuntu will later be hidden by mounting an EBS volume to /home. 
 * configure nodes. specifically,
  * make an sqlite3 database of running hosts and their IP addresses (both public and private)
  * copy the database to each of the nodes (so that they can know addresses of their peers)
  * download a repository of scripts (makefiles) to configure them. the repository is hosted at https://gitlab.eidos.ic.i.u-tokyo.ac.jp/tau/madb_env (TODO: the repository is currently PUBLIC, which is not secure).
  * run the configuration scripts

aws.mk is intended to be lightweight and generic.  you should be able to build your own cluster by changing a few variables.
most madb-specific settings are in the madb_env repository. scripts in the repository configure everything from hostname, /etc/hosts, /etc/fstab, users, ldap (account sharing), NFS (file sharing), apache, php, mysql, etc.  some madb-specific settings are hardwired in aws.mk.

after studying the output of the "make -f aws.mk -n", if you feel it looks OK, run:
```
$ make -f aws.mk
```

it will take a few minutes to bring up a master and a compute node.

there are no particular commands to bring them down. just login

repeating aws.mk
--------------------------

if you run aws.mk when an instance of the specified name is already running,
it does not bring up a new instance of that name. for example, when you repeat
aws.mk twice in a row, the second one does not bring up any node.  the rest
of the configurations still runs. so configuration scripts are all intended
to be idempotent.

customizations
--------------------------

 * put customizations in "config.mk" file in the same directory as aws.mk. an example is in config.mk.example. 
 * in the config.mk, set:
  * n_compute_nodes : to specify the number of compute nodes
  * master_node_instance_type : to specify the instance type of the master node
  * compute_node_instance_type : to specify the instance type of compute nodes
  * ensure_instance_common_opts : to specify additional options you want to give to ensure_instance, if any



