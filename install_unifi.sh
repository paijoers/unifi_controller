#!/bin/bash
# Tiktok konten @nys.pjr 
# Ubiquiti Repository
echo "deb http://www.ui.com/downloads/unifi/debian stable ubiquiti" | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50

sudo apt update
sudo apt upgrade -y

# Menginstal rng-tools
sudo apt install -y rng-tools
sudo sed -i 's/#HRNGDEVICE=/dev/hwrng/HRNGDEVICE=/dev/urandom/' /etc/default/rng-tools
sudo systemctl restart rng-tools

# Menginstal Unifi Controller
# UNIFI_VERSION="7.3.83"
sudo apt install -y unifi
