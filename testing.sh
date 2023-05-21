#!/bin/bash
# @nys.pjr 
# Tested OS: Armbian 20.10 Ubuntu Bionic

# Function to install UniFi Controller
install_unifi() {
    # Add key
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50
    wget -O - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
    
    # Add MongoDB repository
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list

    # Add UniFi repository
    echo "deb https://www.ui.com/downloads/unifi/debian stable ubiquiti" | sudo tee /etc/apt/sources.list.d/unifi.list

    # Update packages
    sudo apt update

    # Install dependencies
    if [[ "$unifi_version" < "7.3" ]]; then
        # Install Java 8
        sudo apt install -y openjdk-8-jre-headless
        export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-$(dpkg --print-architecture)
    else
        # Install Java 11
        sudo apt install -y openjdk-11-jre-headless
        export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-$(dpkg --print-architecture)
    fi

    # Set Java path
    export PATH=$PATH:$JAVA_HOME/bin

    # Install UniFi Controller
    sudo apt install -y unifi

    # Install rng-tools
    sudo apt install -y rng-tools

    # Enable rng-tools service
    sudo sed -i 's|^#HRNGDEVICE=.*|HRNGDEVICE=/dev/urandom|' /etc/default/rng-tools
    sudo systemctl enable rng-tools
    sudo systemctl start rng-tools

    # Disable haveged
    sudo systemctl stop haveged
    sudo systemctl disable haveged
}

# Function to clean up UniFi Controller
cleanup_unifi() {
    # Remove UniFi Controller packages and files
    sudo apt purge -y unifi
    sudo apt autoremove -y
    sudo rm -rf /usr/lib/unifi
    sudo rm -rf /var/lib/unifi
    sudo rm -rf /var/log/unifi
    sudo rm -rf /var/run/unifi
    sudo rm -rf /etc/unifi

    # Ask if user wants to remove Java
    read -p "Do you want to remove Java? (y/n): " remove_java
    if [[ "$remove_java" == "y" ]]; then
        if [[ "$unifi_version" < "7.3" ]]; then
            # Remove Java 8
            sudo apt purge -y openjdk-8-jre-headless
        else
            # Remove Java 11
            sudo apt purge -y openjdk-11-jre-headless
        fi
    fi

    # Remove rng-tools
    sudo apt purge -y rng-tools
    sudo rm /etc/default/rng-tools

    # Enable haveged
    sudo systemctl enable haveged
    sudo systemctl start haveged

    echo "UniFi Controller has been successfully removed."
    exit 0
}

# Show menu and ask for user input
echo "UniFi Controller Installation"
echo "---------------------------"
echo "1. Install UniFi Controller"
echo "2. Clean up UniFi Controller"
read -p "Please enter your choice (1 or 2): " choice

case $choice in
    1)
        install_unifi
        ;;
    2)
        cleanup_unifi
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Update packages
sudo apt update

# Start UniFi Controller
sudo systemctl start unifi

# Enable UniFi Controller to start on boot
sudo systemctl enable unifi

echo "UniFi Controller has been installed and started."
