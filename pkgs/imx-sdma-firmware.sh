#!/bin/bash

unset deb_pkgs
dpkg -l | grep build-essential >/dev/null || deb_pkgs+="build-essential "

if [ "${deb_pkgs}" ] ; then
	echo "Installing: ${deb_pkgs}"
	sudo apt-get update
	sudo apt-get -y install ${deb_pkgs}
fi

git_sha="origin/master"
project="sdma-firmware"
server="git://git.pengutronix.de/git/imx"
system=$(lsb_release -sd | awk '{print $1}')

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	git clone ${server}/${project}.git ${HOME}/git/${project}/
fi

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	rm -rf ${HOME}/git/${project}/ || true
	echo "error: git failure, try re-runing"
	exit
fi

cd ${HOME}/git/${project}/

git checkout master -f
git pull || true
git branch ${git_sha}-build -D || true
git checkout ${git_sha} -b ${git_sha}-build

make

if [ ! -d /lib/firmware/sdma ] ; then
	sudo mkdir -p /lib/firmware/sdma || true
fi

sudo cp sdma*.bin /lib/firmware/sdma
make clean

if [ ! -f /boot/initrd.img-$(uname -r) ] ; then
	sudo update-initramfs -c -k $(uname -r)
else
	sudo update-initramfs -u -k $(uname -r)
fi

if [ -f /boot/vmlinuz-$(uname -r) ] ; then
	sudo cp -v /boot/vmlinuz-$(uname -r) /boot/uboot/zImage
fi

if [ -f /boot/initrd.img-$(uname -r) ] ; then
	sudo cp -v /boot/initrd.img-$(uname -r) /boot/uboot/initrd.img
fi

echo "sdma firmware installed"
echo "please reboot"
