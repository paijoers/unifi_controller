#!/bin/bash
# Tiktok konten @nys.pjr 
# Ubiquiti Repository
echo "deb http://www.ui.com/downloads/unifi/debian stable ubiquiti" | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50

# Opsional menambahkan arsitektur armhf
sudo dpkg --add-architecture armhf
sudo apt update
sudo apt install libc6:armhf
sudo apt upgrade -y

# Menginstal rng-tools
sudo apt install -y rng-tools
sudo sed -i 's/#HRNGDEVICE=/dev/hwrng/HRNGDEVICE=/dev/urandom/' /etc/default/rng-tools
sudo systemctl restart rng-tools

# Menginstal Unifi Controller
# Silahkan edit versi sesuai selera
UNIFI_VERSION="6.5.51"
sudo apt install -y unifi=${UNIFI_VERSION}
