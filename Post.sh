#!/bin/bash



echo "[+] Hostapd and dnsmasq are running"
echo "[*] Press Ctrl+C to exit"
trap ctrl_c INT
function ctrl_c() {
	echo "[*] Killing hostapd and dnsmasq"
	killall hostapd
	killall dnsmasq
	echo "[*] Restoring iptables"
	iptables --flush
	iptables --table nat --flush
	iptables --delete-chain
	iptables --table nat --delete-chain
	echo "[*] Restoring ip_forward"
	echo 0 > /proc/sys/net/ipv4/ip_forward
	echo "[*] Done"
	exit
}
while true; do
	sleep 1
done
