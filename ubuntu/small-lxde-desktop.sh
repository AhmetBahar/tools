#!/bin/sh -e

sudo apt-get update
sudo apt-get -y upgrade

#Wheezy: 281 pkgs, 94.9MB, 280MB
#sudo apt-get -y install lightdm lxde-core

#Ubuntu Raring:
sudo apt-get -y install lxde-core slim xserver-xorg-video-modesetting xserver-xorg

if [ "x${USER}" != "xroot" ] ; then
	echo "#!/bin/sh" > ${USER}/.xinitrc
	echo "" >> ${USER}/.xinitrc
	echo "exec startlxde" >> ${USER}/.xinitrc

	chmod +x ${USER}/.xinitrc

	#/etc/slim.conf modfications:
	sudo sed -i -e 's:default,start:startlxde,default,start:g' /etc/slim.conf
	echo "default_user	${USER}" | sudo tee -a /etc/slim.conf >/dev/null
	echo "auto_login	yes" | sudo tee -a /etc/slim.conf >/dev/null
fi

echo "Please Reboot"
