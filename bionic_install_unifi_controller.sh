#!/bin/bash
# @nys.pjr 
# Tested OS: Armbian 20.10 Ubuntu Bionic

# Remove unifi_sysvinit_all.deb file if it exists
if [ -f unifi_sysvinit_all.deb ]; then
    rm unifi_sysvinit_all.deb
fi

# Set Java path
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin

# Update packages
sudo apt update

# Install rng-tools
sudo apt install -y rng-tools
sudo touch /etc/default/rng-tools
sudo sed -i 's|^#HRNGDEVICE=.*|HRNGDEVICE=/dev/urandom|' /etc/default/rng-tools
sudo systemctl restart rng-tools

# Disable haveged
sudo systemctl stop haveged
sudo systemctl disable haveged

# Install necessary dependencies
sudo apt install -y openjdk-11-jre-headless mongodb

# Download UniFi Controller version 7.3.83
wget -c https://dl.ui.com/unifi/7.3.83/unifi_sysvinit_all.deb

# Install UniFi Controller
sudo dpkg -i unifi_sysvinit_all.deb

# Install Unifi Controller
sudo apt install unifi -y

# Start UniFi Controller
sudo systemctl start unifi

# Enable UniFi Controller to start on boot
sudo systemctl enable unifi
