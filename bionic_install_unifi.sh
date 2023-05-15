#!/bin/bash
# @nys.pjr 
# Armbian 20.10 Ubuntu Bionic

# Hapus file unifi_sysvinit_all.deb jika ada
if [ -f unifi_sysvinit_all.deb ]; then
    # Jika file sudah ada, hapus file tersebut
    rm unifi_sysvinit_all.deb
fi

# Memperbarui paket
sudo apt update

# Menginstal rng-tools
sudo apt install -y rng-tools
sudo touch /etc/default/rng-tools
sudo sed -i 's/#HRNGDEVICE=\/dev\/hwrng/HRNGDEVICE=\/dev\/urandom/' /etc/default/rng-tools
sudo systemctl restart rng-tools
# sudo /etc/init.d/rng-tools restart

# Disable haveged
sudo systemctl stop haveged
sudo systemctl disable haveged

# Memasang dependensi yang diperlukan
sudo apt install -y openjdk-8-jre-headless mongodb

# Mengunduh UniFi Controller
wget -c https://dl.ui.com/unifi/7.2.95/unifi_sysvinit_all.deb

# Memasang UniFi Controller
sudo dpkg -i unifi_sysvinit_all.deb

# Menginstal Unifi Controller
sudo apt install unifi -y

# Mengatur UniFi Controller untuk memulai pada saat boot
sudo systemctl enable unifi
