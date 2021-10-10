include ../common.mk
nvidia_gpu_exists := $(shell if lspci | grep -i nvidia > /dev/null; then echo 1 ; fi)
ifneq ($(nvidia_gpu_exists),)
  targets := cuda
else
  targets :=
endif

pin_dl := cuda-ubuntu2004.pin
pin_url := https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/$(pin_dl)
pin := /etc/apt/preferences.d/cuda-repository-pin-600
#key_pub := /var/cuda-repo-ubuntu2004-11-1-local/7fa2af80.pub
key_pub := /var/cuda-repo-ubuntu2004-11-4-local/7fa2af80.pub

deb := cuda-repo-ubuntu2004-11-1-local_11.1.0-455.23.05-1_amd64.deb
deb_url := https://developer.download.nvidia.com/compute/cuda/11.1.0/local_installers/$(deb)
nvcc := /usr/local/cuda-11.1/bin/nvcc
#deb := cuda-repo-ubuntu2004-11-4-local_11.4.2-470.57.02-1_amd64.deb
#deb_url := https://developer.download.nvidia.com/compute/cuda/11.4.2/local_installers/$(deb)
#nvcc := /usr/local/cuda-11.4/bin/nvcc

uname_r := $(shell uname -r)
header_dir := /usr/src/linux-headers-$(uname_r)
header := $(header_dir)/Kconfig

OK : $(targets)

$(header) :
	$(aptinst) linux-headers-$(uname_r)

$(pin) : $(header)
	wget -O $(pin_dl) $(pin_url)
	$(inst) $(pin_dl) $(pin)

$(deb) : $(pin)
	wget -O $(deb) $(deb_url)
	touch $(deb)

$(nvcc) : $(deb)
	dpkg -i $(deb)
	apt-key add $(key_pub)
	$(apt) update
	$(aptinst) cuda

persistenced : $(nvcc)
	pgrep -f nvidia-persistenced || /usr/bin/nvidia-persistenced --verbose

cuda : persistenced
