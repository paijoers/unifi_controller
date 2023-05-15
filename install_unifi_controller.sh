#!/bin/bash
# @nys.pjr 
# Tested OS: Armbian 20.10 Ubuntu Bionic

# Show menu and ask for user input
echo "UniFi Controller Installation"
echo "---------------------------"
echo "1. Install UniFi Controller via apt"
echo "2. Manual Install (Install UniFi Controller without using apt)"
echo "3. Cancel"
echo "4. Help"
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        # Add UniFi repository key
        wget -O - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
        echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list

        # Add UniFi repository
        echo "deb https://www.ui.com/downloads/unifi/debian stable ubiquiti" | sudo tee /etc/apt/sources.list.d/unifi.list

        # Update packages again
        sudo apt update

        # Install dependencies
        sudo apt install -y openjdk-11-jre-headless mongodb

        # Install UniFi Controller
        sudo apt install -y unifi
        ;;
    2)
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
        ;;
    3)
        echo "Installation canceled."
        exit 0
        ;;
    4)
        echo "Help:"
        echo "1. Install UniFi Controller via apt: Installs UniFi Controller using the official repository."
        echo "2. Manual Install: Allows you to update UniFi Controller by downloading and manually installing the .deb package."
        echo "3. Cancel: Exits the installation process without making any changes."
        echo "4. Help: Displays this help message."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

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

# Start UniFi Controller
sudo systemctl start unifi

# Enable UniFi Controller to start on boot
sudo systemctl enable unifi

echo "UniFi Controller has been installed and started."
