
How noip2 update client works

[1] Given -C option, it will ask questions like this and end up creating a configuration file (default /usr/local/etc/no-ip.conf).  As far as I remember this happens when there is no configuration file.

root@ip-172-31-28-11:~/taulec_env/scripts/J22dns# ./noip-2.1.9-1/noip2 -C -u <noip-user-name> -p <password>

Auto configuration for Linux client of no-ip.com.

2 hosts are registered to this account.
Do you wish to have them all updated?[N] (y/N)  n
Do you wish to have host [taulec.zapto.org] updated?[N] (y/N)  n
Do you wish to have host [taulex.zapto.org] updated?[N] (y/N)  y
Please enter an update interval:[30]  

New configuration file '/usr/local/etc/no-ip2.conf' created.

[2] Once you made a configuration file, you do

./noip-2.1.9-1/noip2 -i xxx.xxx.xxx.xxx

and it will update the DNS record on noip.

[3] Automating everything is a bit tricky due to the interaction in the step [1].

While something like

 echo nny | ./noip-2.1.9-1/noip2 -C -u <noip-user-name> -p <passwd>

is possible, this requires a knowledge about which hosts are registered on noip2 and in which order they appear.

I am not able to find a command line specifying which hostname you want to update.

