#!/usr/bin/bash

if (( $# != 3 )); then
    echo "[ERROR] Illegal number of parameters."
    echo "[-] Syntax: recon.sh [interface] [SSID] [PASSPHRASE]"
    echo '[-] Example: recon.sh wlan0 my_ssid my_passhphrase'
    exit -1
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
    echo "[INFO] hostapd successfully installed. Starting AP configuration."
fi

# Setup hostapd configuration file
sudo touch ./conf/hostapd.conf
sudo echo "interface=$1
bridge=br0
driver=nl80211
ssid=$2
hw_mode=g
channel=7
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=3
wpa_passphrase=$3
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP" > ./conf/hostapd.conf

cp ./conf/hostapd.conf /etc/hostapd/hostapd.conf
cp /.conf/hostapd /etc/default/hostapd

# Enable ipv4 forwarding
sudo sysctl -w net.ipv4.ip_forward=1

sudo hostapd /etc/hostapd/hostapd.conf
