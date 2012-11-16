#!/bin/bash -e

network_down () {
	echo "Network Down"
	exit
}

ping -c1 www.google.com | grep ttl &> /dev/null || network_down

install_pkgs () {
	unset deb_pkgs
	dpkg -l | grep build-essential >/dev/null || deb_pkgs+="build-essential "
	dpkg -l | grep gstreamer-tools >/dev/null || deb_pkgs+="gstreamer-tools "
	dpkg -l | grep libgstreamer0.10-dev >/dev/null || deb_pkgs+="libgstreamer0.10-dev "

	if [ "${deb_pkgs}" ] ; then
		echo "Installing: ${deb_pkgs}"
		sudo apt-get update
		sudo apt-get -y install ${deb_pkgs}
	fi
}

git_generic () {
	echo "Building: ${project}: ${git_sha}"
	if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
		git clone ${server}/${project}.git ${HOME}/git/${project}/
	fi

	if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
		rm -rf ${HOME}/git/${project}/ || true
		echo "error: git failure, try re-runing"
		exit
	fi

	cd ${HOME}/git/${project}/
	make clean &>/dev/null

	git checkout master -f
	git pull || true
	git branch ${git_sha}-build -D || true
	git checkout ${git_sha} -b ${git_sha}-build
}

git_sha="origin/master"
project="gst-dsp"
server="git://github.com/felipec"

git_generic

./configure
make CROSS_COMPILE= 
sudo make install

git_sha="origin/master"
project="gst-omapfb"
server="git://github.com/felipec"

git_generic

make CROSS_COMPILE= 
sudo make install

git_sha="origin/firmware"
project="dsp-tools"
server="git://github.com/felipec"

git_generic

if [ ! -d /lib/dsp/ ] ; then
	sudo mkdir -p /lib/dsp || true
fi

sudo cp -v firmware/test.dll64P /lib/dsp/

git_sha="origin/master"
project="dsp-tools"
server="git://github.com/felipec"

git_generic

make CROSS_COMPILE= 
sudo make install

