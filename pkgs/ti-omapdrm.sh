#!/bin/bash -e

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

#package list from:
#http://anonscm.debian.org/gitweb/?p=collab-maint/xf86-video-omap.git;a=blob;f=debian/control;hb=HEAD
sudo apt-get update

#libdrm Installs: (wheezy)
#dh-autoreconf libpciaccess-dev libpciaccess0 libpthread-stubs0
#libpthread-stubs0-dev libx11-dev libxau-dev libxcb1-dev libxdmcp-dev pkg-config
#x11proto-core-dev x11proto-input-dev x11proto-kb-dev xorg-sgml-doctools xtrans-dev
sudo apt-get -y build-dep libdrm

unset deb_pkgs
pkg="xutils-dev"
check_dpkg
pkg="debhelper"
check_dpkg
pkg="libudev-dev"
check_dpkg
pkg="x11proto-core-dev"
check_dpkg
pkg="libxext-dev"
check_dpkg
pkg="x11proto-fonts-dev"
check_dpkg
pkg="x11proto-gl-dev"
check_dpkg
pkg="x11proto-xf86dri-dev"
check_dpkg
pkg="x11proto-xf86dri-dev"
check_dpkg
pkg="xserver-xorg-dev"
check_dpkg

if [ "${deb_pkgs}" ] ; then
	echo ""
	echo "Installing: ${deb_pkgs}"
	sudo apt-get -y install ${deb_pkgs}
	sudo apt-get clean
	echo "--------------------"
fi

git_sha="libdrm-2.4.43"
project="libdrm"
server="git://anongit.freedesktop.org/mesa/drm"

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	git clone ${server} ${HOME}/git/${project}/ || true
fi

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	rm -rf ${HOME}/git/${project}/ || true
	echo "error: git failure, try re-runing"
	exit
fi

echo ""
echo "Building ${project}"
echo ""

cd ${HOME}/git/${project}/

make distclean &> /dev/null
git checkout master -f
git pull || true
git branch ${git_sha}-build -D || true
git checkout ${git_sha} -b ${git_sha}-build

./autogen.sh --prefix=/usr --libdir=/usr/lib/`dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null`/ \
--disable-libkms --disable-intel --disable-radeon --disable-nouveau --disable-vmwgfx \
--enable-omap-experimental-api --disable-manpages

make
sudo make install
make distclean &> /dev/null

git_sha="origin/master"
project="xf86-video-omap"
server="git://anongit.freedesktop.org/xorg/driver"

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	git clone ${server}/${project}.git ${HOME}/git/${project}/ || true
fi

if [ ! -f ${HOME}/git/${project}/.git/config ] ; then
	rm -rf ${HOME}/git/${project}/ || true
	echo "error: git failure, try re-runing"
	exit
fi

echo ""
echo "Building ${project}"
echo ""

cd ${HOME}/git/${project}/

make distclean &> /dev/null
git checkout master -f
git pull || true
git branch ${git_sha}-build -D || true
git checkout ${git_sha} -b ${git_sha}-build

./autogen.sh --prefix=/usr
make
sudo make install

if [ ! -d /etc/X11/ ] ; then
	sudo mkdir -p /etc/X11/ || true
fi

if [ -f /etc/X11/xorg.conf ] ; then
	sudo rm -rf /etc/X11/xorg.conf.bak || true
	sudo mv /etc/X11/xorg.conf /etc/X11/xorg.conf.bak
fi

cat > /tmp/xorg.conf <<-__EOF__
	Section "Device"
	        Identifier      "omap"
	        Driver          "omap"
	EndSection

__EOF__

sudo cp -v /tmp/xorg.conf /etc/X11/xorg.conf
