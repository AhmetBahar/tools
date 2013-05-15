#!/bin/sh

#Based off:
#https://github.com/beagleboard/meta-beagleboard/blob/master/meta-beagleboard-extras/recipes-support/usb-gadget/gadget-init/g-ether-load.sh

function get_devmem()
{
	/usr/bin/devmem2 $1 | grep ": " | cut -d ":" -f 2|cut -d "x" -f 2
}

function hex_to_mac_addr()
{
	addr=$1
	n=0
	mac_addr=$(echo ${addr} | while read -r -n2 c; do 
		if [ ! -z "$c" ]; then
			if [ $n -ne 0 ] ; then
				echo -n ":${c}"
			else
				echo -n "${c}"
			fi
		fi
		n=$(($n+1))
	done)
	echo ${mac_addr}
}

function reverse_bytes()
{
	addr=$1
	New_addr=$(echo ${addr} | while read -r -n2 c; do 
		if [ ! -z "$c" ]; then
			New_addr=${c}${New_addr}
		else echo
			echo ${New_addr}
		fi
	done)
	echo ${New_addr}
}

DEVMEM_ADDR_LO=$(get_devmem 0x44e10638|bc)
DEVMEM_ADDR_LO=$(reverse_bytes ${DEVMEM_ADDR_LO})

DEVMEM_ADDR_HI=$(get_devmem 0x44e1063C)
DEVMEM_ADDR_HI=$(reverse_bytes ${DEVMEM_ADDR_HI})

DEV_ADDR=$(hex_to_mac_addr "${DEVMEM_ADDR_HI}${DEVMEM_ADDR_LO}")

SERIAL_NUMBER=$(hexdump -e '8/1 "%c"' /sys/bus/i2c/devices/0-0050/eeprom -s 14 -n 2)-$(hexdump -e '8/1 "%c"' /sys/bus/i2c/devices/0-0050/eeprom -s 16 -n 12)
ISBLACK=$(hexdump -e '8/1 "%c"' /sys/bus/i2c/devices/0-0050/eeprom -s 8 -n 4)

BLACK=""

if [ "${ISBLACK}" = "BBBK" ] ; then
	BLACK="Black"
fi

if [ "${ISBLACK}" = "BNLT" ] ; then
	BLACK="Black"
fi

echo "DevAddr:${DEV_ADDR}"

modprobe g_multi file=/dev/mmcblk0p1 cdrom=0 stall=0 removable=1 nofua=1 iSerialNumber=${SERIAL_NUMBER} iManufacturer=Circuitco  iProduct=BeagleBone${BLACK} host_addr=${DEV_ADDR}

sleep 1

if [ ! -f /etc/udhcpd.conf ] ; then
	echo "start      192.168.7.1" > /etc/udhcpd.conf
	echo "end        192.168.7.1" >> /etc/udhcpd.conf
	echo "interface  usb0" >> /etc/udhcpd.conf
	echo "max_leases 1" >> /etc/udhcpd.conf
	echo "option subnet 255.255.255.252" >> /etc/udhcpd.conf
fi

/sbin/ifconfig usb0 192.168.7.2 netmask 255.255.255.252
/usr/sbin/udhcpd -f -S /etc/udhcpd.conf
