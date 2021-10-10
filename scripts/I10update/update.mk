#
# upgrade.mk --- perform apt update and apt upgrade
#

include ../common.mk

OK :
	$(apt) update
	$(apt) upgrade
