#
# timezone.mk --- set the timezone
# 
include ../common.mk

OK :
	timedatectl set-timezone Asia/Tokyo
