#!/bin/bash
# @nys.pjr 
# Tested OS: Armbian 20.10 Ubuntu Bionic

# Stop UniFi Controller
sudo systemctl stop unifi

# Disable UniFi Controller from starting on boot
sudo systemctl disable unifi

# Uninstall UniFi Controller
sudo apt remove unifi -y

# Uninstall OpenJDK 11
sudo apt remove openjdk-11-* -y

# Uninstall MongoDB
sudo apt remove mongodb-org* -y

# Uninstall rng-tools
sudo apt remove rng-tools -y

# Re-enable haveged
sudo systemctl start haveged
sudo systemctl enable haveged

echo "UniFi Controller and related packages have been uninstalled."
