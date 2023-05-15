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

# Remove UniFi source list
sudo rm /etc/apt/sources.list.d/unifi.list

# Remove MongoDB source list
sudo rm /etc/apt/sources.list.d/mongodb-org-4.4.list

# Remove unused packages
sudo apt autoremove -y

# Re-enable haveged
sudo systemctl start haveged
sudo systemctl enable haveged

echo "UniFi Controller, related packages, and source lists have been completely uninstalled."
