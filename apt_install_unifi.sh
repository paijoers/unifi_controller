#!/bin/bash
# @nys.pjr 
# Tested OS: Armbian 20.10 Ubuntu Bionic

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

# Option to install UniFi Controller via apt
read -p "Do you want to install UniFi Controller via apt? (y/n): " choice
if [[ $choice =~ ^[Yy]$ ]]; then
    # Add UniFi repository key
    wget -O - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
    wget -O - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
    wget -O - https://dl.ui.com/unifi/unifi-repo.gpg | sudo apt-key add -
    
    # Add UniFi repository
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
    echo "deb https://www.ui.com/downloads/unifi/debian stable ubiquiti" | sudo tee /etc/apt/sources.list.d/unifi.list
    
    # Update packages again
    sudo apt update
    
    # Install dependencies
    sudo apt install -y openjdk-11-jre-headless mongodb

    # Install UniFi Controller
    sudo apt install -y unifi
else
    # Check if unifi_sysvinit_all.deb file exists
    if [ -f unifi_sysvinit_all.deb ]; then
        rm unifi_sysvinit_all.deb
    fi

    # Download UniFi Controller version 7.3.83
    wget -c https://dl.ui.com/unifi/7.3.83/unifi_sysvinit_all.deb

    # Install dependencies
    sudo apt install -y openjdk-11-jre-headless mongodb

    # Install UniFi Controller from downloaded package
    sudo dpkg -i unifi_sysvinit_all.deb

    # Install dependencies
    sudo apt install -f -y
fi

# Start UniFi Controller
sudo systemctl start unifi

# Enable UniFi Controller to start on boot
sudo systemctl enable unifi

echo "UniFi Controller has been installed and started."
