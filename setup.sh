#!/bin/bash

if (( $# != 3 )); then
    echo "[ERROR] Illegal number of parameters."
    echo "[-] Syntax: recon.sh [interface] [SSID] [PASSPHRASE]"
    echo '[-] Example: recon.sh wlan0 my_ssid my_passhphrase'
    exit -1
fi

if ($1 == '--help'); then
    echo "[-] Syntax: recon.sh [interface] [SSID] [PASSPHRASE]"
    echo '[-] Example: recon.sh wlan0 my_ssid my_passhphrase'
    exit 0
fi

echo "[INFO] Creating access point through $1"

# Interface check
ip link show $1 > /dev/null 2>&1

ret_code=$?

if [ $ret_code != 0 ]; then
    echo "[ERROR] Device \"$1\" does not exit. Aborting."
    exit -1
fi

sudo apt-get install -y hostapd

if [[ $? > 0 ]]
then
    echo "[ERROR] Error during hostapd installation. Aborting."
    exit
else
    echo "[INFO] hostapd successfully installed."
fi

sudo systemctl unmask hostapd
sudo systemctl enable hostapd


sudo apt install -y dnsmasq

if [[ $? > 0 ]]
then
    echo "[ERROR] Error during dnsmasq installation. Aborting."
    exit
else
    echo "[INFO] dnsmasq successfully installed."
fi

sudo DEBIAN_FRONTEND=noninteractive apt install -y netfilter-persistent iptables-persistent

if [[ $? > 0 ]]
then
    echo "[ERROR] Error during iptables/netfilter installation. Aborting."
    exit
else
    echo "[INFO] iptables/netfilter successfully installed."
fi


echo "interface $1
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant" >> ./conf/dhcpcd.conf

cp ./conf/dhcpcd.conf /etc/dhcpcd.conf


sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# Enable ipv4 forwarding
sudo sysctl -w net.ipv4.ip_forward=1

sudo netfilter-persistent save

sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig

echo "

interface=$1 # Listening interface
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
                # Pool of IP addresses served via DHCP
domain=wlan     # Local wireless DNS domain
address=/gw.wlan/192.168.4.1
                # Alias for this router
" >> conf/dnsmasq.conf

sudo cp conf/dnsmasq.conf /etc/dnsmasq.conf

sudo rfkill unblock wlan

# Setup hostapd configuration file
sudo echo "
country_code=IT
interface=$1
ssid=$2
hw_mode=g
channel=7
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$3
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP" > conf/hostapd.conf

sudo cp ./conf/hostapd.conf /etc/hostapd/hostapd.conf
# cp /.conf/hostapd /etc/default/hostapd

# sudo hostapd /etc/hostapd/hostapd.conf

echo "[DONE] Reboot the system to start the AP."
echo "[DONE] Run \"sudo sysctl -w net.ipv4.ip_forward=1\" after reboot."
