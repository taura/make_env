#
# dns.mk --- set no-ip client
#
include ../common.mk

dns_name:=$(call hvar,dns_name)
ifneq ($(dns_name),)
  targets := dns
#  targets :=
else
  targets := 
endif

public_ip := $(query hvar,PublicIpAddress)

OK : $(targets)

dns : noip

noip : noip-2.1.9-1/noip2 /usr/local/etc/no-ip2.conf
	noip-2.1.9-1/noip2 -i $(public_ip)

noip-2.1.9-1/noip2 : noip-duc-linux.tar.gz
	tar xf noip-duc-linux.tar.gz
	cd noip-2.1.9-1 && make

/usr/local/etc/no-ip2.conf : 

