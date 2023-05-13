#!/bin/bash
# @nys.pjr 

# Menginstal rng-tools
sudo apt install -y rng-tools
sudo touch /etc/default/rng-tools
sudo sed -i 's/#HRNGDEVICE=\/dev\/hwrng/HRNGDEVICE=\/dev\/urandom/' /etc/default/rng-tools
sudo systemctl restart rng-tools
# sudo /etc/init.d/rng-tools restart

# Disable haveged
sudo systemctl stop haveged
sudo systemctl disable haveged

# Ubiquiti Repository
echo "deb http://www.ui.com/downloads/unifi/debian stable ubiquiti" | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50
sudo apt update

# Menginstal java
sudo apt install openjdk-11-jre-headless

# Menginstal Unifi Controller
sudo apt install unifi -y
sudo apt --fix-broken install -y
