#!/bin/bash
# @nys.pjr 
# Tested OS: Armbian 20.10 Ubuntu Bionic

# Stop UniFi Controller
sudo systemctl stop unifi

# Disable UniFi Controller from starting on boot
sudo systemctl disable unifi

# Uninstall UniFi Controller with purge
sudo apt purge unifi -y

# Uninstall OpenJDK 11 with purge
sudo apt purge openjdk-11-* -y

# Uninstall MongoDB with purge
sudo apt purge mongodb-org* -y

# Uninstall rng-tools with purge
sudo apt purge rng-tools -y

# Re-enable haveged
sudo systemctl start haveged
sudo systemctl enable haveged

echo "UniFi Controller and related packages have been completely uninstalled."
