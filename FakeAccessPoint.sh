#!/bin/bash
if [ $# -ne 4 ]; then
	echo "Usage: ./FakeAccessPoint.sh <interfaceName> <fowardInterfaceName> <apName> <passphrase>"
	echo "<interfaceName>: The interface to use to create the fake access point Ex. wlan0"
	echo "<fowardInterfaceName> The interface to use to give the fake access point internet access. Must have an internet connection. Ex. eth0, wlan0"
	echo "<apName> The name for you access point Ex. TestAp"
	echo "<passphrase> The password for your access point"
	exit 1
fi
apInterfaceName=$1
STR="Hello World!"
SUCCESS='\032[0;31m[+] \033[0m'
ERROR='\033[0;31m[-] \033[0m'
INFOSIGN='\034[0;31m[*] \033[0m'

# check if the interface is already in monitor mode
if [[ $(iwconfig $apInterfaceName | grep Monitor) ]]; then
	echo "Interface is already in monitor mode"
else
	# put the interface in monitor mode
	sudo airmon-ng start $apInterfaceName
fi

# check if the interface is in monitor mode
if [[ $(iwconfig $apInterfaceName | grep Monitor) ]]; then
	echo "Interface is in monitor mode"
else
	echo "Error: Interface is not in monitor mode and could not set it"
	exit 1
fi

fowardInterfaceName=$2

# check if the interface has internet access
if [[ $(ping -c 1 google.com | grep "1 received") ]]; then
	echo "Interface has internet access"
else
	echo "Error: Interface does not have internet access"
	exit 1
fi

# check if the interface is in managed mode
if [[ $(iwconfig $fowardInterfaceName | grep Managed) ]]; then
	echo "Interface is in managed mode"
else
	echo "Error: Interface $fowardInterfaceName is not in managed mode"
	exit 1
fi

# check if the interface is up
if [[ $(ifconfig $fowardInterfaceName | grep UP) ]]; then
	echo "Interface $fowardInterfaceName is up"
else
	echo "Error: Interface $fowardInterfaceName is not up"
	exit 1
fi

apName=$3

passphrase=$4

if [[ $(dpkg -s hostapd | grep Status) ]]; then
	echo "hostapd is installed"
else
	echo "hostapd is not installed"
	sudo apt-get install hostapd
fi

if [[ $(dpkg -s apache2 | grep Status) ]]; then
	echo "apache2 is installed"
else
	echo "apache2 is not installed"
	sudo apt-get install apache2
fi

if [[ $(dpkg -s dnsmasq | grep Status) ]]; then
	echo "dnsmasq is installed"
else
	echo "dnsmasq is not installed"
	sudo apt-get install dnsmasq
fi
echo $passphrase
echo "interface=$apInterfaceName" > hostapd.conf
echo "driver=nl80211" >> hostapd.conf
echo "ssid=$apName" >> hostapd.conf
echo "hw_mode=g" >> hostapd.conf
echo "channel=11" >> hostapd.conf
echo "macaddr_acl=0" >> hostapd.conf
echo "auth_algs=1" >> hostapd.conf
echo "ignore_broadcast_ssid=0" >> hostapd.conf
echo "wpa=2" >> hostapd.conf
echo "wpa_passphrase=$passphrase" >> hostapd.conf
echo "wpa_key_mgmt=WPA-PSK" >> hostapd.conf
echo "wpa_pairwise=CCMP" >> hostapd.conf
echo "wpa_group_rekey=86400" >> hostapd.conf
echo "ieee80211n=1" >> hostapd.conf
echo "wme_enabled=1" >> hostapd.conf
echo "interface=$apInterfaceName" > dnsmasq.conf
echo "dhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h" >> dnsmasq.conf
echo "dhcp-option=3,192.168.1.1" >> dnsmasq.conf
echo "dhcp-option=6,192.168.1.1" >> dnsmasq.conf
echo "server=8.8.8.8" >> dnsmasq.conf
echo "log-queries" >> dnsmasq.conf
echo "log-dhcp" >> dnsmasq.conf
echo "listen-address=127.0.0.1" >> dnsmasq.conf

xdotool key super+d
#gnome-terminal --geometry=50*20+0+1000 --command="bash -c \"./Post.sh\""
xterm -geometry 60x30+0+2000 -e "./Post.sh" &
echo $SUCCESS + 'Starting hostapd'

#gnome-terminal --geometry=50x20+0+0 --command="bash -c \"hostapd hostapd.conf\""
xterm -geometry 60x30+0+0 -e "hostapd hostapd.conf" &
ifconfig $apInterfaceName up 192.168.1.1 netmask 255.255.255.0
route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1
echo $SUCCESS + 'Starting dnsmassq'
# test
#gnome-terminal --geometry=50x20+2000+0 -- bash -ic"dnsmasq -C dnsmasq.conf -d ; exec bash "
xterm -geometry 60x30+2000+0 -e "dnsmasq -C dnsmasq.conf -d" &
iptables --table nat --append POSTROUTING --out-interface $fowardInterfaceName -j MASQUERADE
iptables --append FORWARD --in-interface $apInterfaceName -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward
chmod +x Post.sh
#


