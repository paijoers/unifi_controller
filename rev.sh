#!/bin/bash
# @nys.pjr 
# Tested OS: Armbian 20.10 Ubuntu Bionic

set -e

install_rng_tools() {
    sudo apt install -y rng-tools
    if grep -q "^HRNGDEVICE=" /etc/default/rng-tools; then
        # Replace the line with the new value
        sudo sed -i "s|^HRNGDEVICE=.*|HRNGDEVICE=/dev/urandom|" /etc/default/rng-tools
    else
        # Add the line if it doesn't exist
        echo "HRNGDEVICE=/dev/urandom" | sudo tee -a /etc/default/rng-tools
    fi
    sudo systemctl restart rng-tools
    sudo systemctl stop haveged
    sudo systemctl disable haveged
}

install_unifi_apt() {
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50
    wget -O - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    echo "deb https://www.ui.com/downloads/unifi/debian stable ubiquiti" | sudo tee /etc/apt/sources.list.d/unifi.list
    sudo apt update
    sudo apt install -y openjdk-11-jre-headless
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-$(dpkg --print-architecture)
    export PATH=$PATH:$JAVA_HOME/bin
    install_rng_tools
    sudo apt install -y unifi
    sudo systemctl start unifi
    sudo systemctl enable unifi
    echo "UniFi Controller has been installed and started."
}

install_unifi_manual() {
    # Check if unifi_sysvinit_all.deb file exists
    if [ -f unifi_sysvinit_all.deb ]; then
        echo "Previous UniFi Controller package found. Removing..."
        rm unifi_sysvinit_all.deb
    fi

    read -p "Enter the UniFi Controller version you want to install (e.g., 7.3.83): " version
    download_url="https://dl.ui.com/unifi/$version/unifi_sysvinit_all.deb"
    response=$(curl -s -o /dev/null -I -w "%{http_code}" "$download_url")
    if [[ $response -eq 200 ]]; then
        # Download UniFi Controller package
        wget -c "$download_url" -O unifi_sysvinit_all.deb
        
        # Install dependencies (Java and MongoDB)
        if dpkg --compare-versions "$version" lt "7.3.76"; then
            # Install Java 8
            sudo apt install -y openjdk-8-jre-headless
            export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-$(dpkg --print-architecture)
            export PATH=$PATH:$JAVA_HOME/bin
        else
            # Install Java 11
            sudo apt install -y openjdk-11-jre-headless
            export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-$(dpkg --print-architecture)
            export PATH=$PATH:$JAVA_HOME/bin
        fi
        
        # Install MongoDB
        wget -O - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
        echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
        sudo apt update
        sudo apt install -y mongodb

        # Install UniFi Controller
        sudo dpkg -i unifi_sysvinit_all.deb
        install_rng_tools
        sudo apt install -fy
        sudo systemctl start unifi
        sudo systemctl enable unifi
        echo "UniFi Controller has been installed and started."
    else
        echo "Invalid version or Link not found. Aborting installation."
        exit 1
    fi
}

cleanup_unifi() {
    read -p "Do you want to remove Java as well? (y/n): " remove_java
    if [[ $remove_java == "y" ]]; then
        java_packages=$(dpkg -l | grep -E "openjdk-[0-9]+-jdk|oracle-java[0-9]+-installer" | awk '{ print $2 }')
        if [[ -n $java_packages ]]; then
            echo "Uninstalling Java packages..."
            sudo apt-get remove --purge -y $java_packages
            sudo apt autoremove -y
        else
            echo "No Java packages installed."
        fi
    fi

    # Check if there are MongoDB packages installed
    mongodb_packages=$(dpkg -l | grep mongodb | awk '{ print $2 }')
    # Get the list of installed MongoDB packages
    if [[ -n $mongodb_packages ]]; then
        echo "Uninstalling MongoDB packages..."
        # Remove MongoDB packages
        sudo apt-get remove --purge -y $mongodb_packages
    else
        echo "No MongoDB packages installed."
    fi

    # Get the list of installed rng-tools packages
    rngtools_packages=$(dpkg -l | grep rng-tools | awk '{ print $2 }')
    # Check if there are rng-tools packages installed
    if [[ -n $rngtools_packages ]]; then
        echo "Uninstalling rng-tools packages..."
        # Enable haveged service to generate random numbers
        sudo systemctl enable haveged
        sudo systemctl start haveged
        # Remove rng-tools packages
        sudo apt-get remove --purge -y $rngtools_packages
    else
        echo "No rng-tools packages installed."
    fi

    # Get the list of installed UniFi Controller packages
    unifi_packages=$(dpkg -l | grep unifi | awk '{ print $2 }')
    # Check if there are UniFi Controller packages installed
    if [[ -n $unifi_packages ]]; then
        echo "Uninstalling UniFi Controller packages..."
        # Stop UniFi Controller service
        sudo systemctl stop unifi
        # Disable UniFi Controller service at boot
        sudo systemctl disable unifi
        # Remove UniFi Controller packages
        sudo apt-get remove --purge -y $unifi_packages
    else
        echo "No UniFi Controller packages installed."
    fi

    # Clean up unused packages
    sudo apt-get autoremove -y

    exit 0
}

echo -e "\n-- UniFi Controller Installation --\n"
echo "1. Install via apt"
echo "2. Install custom version"
echo "3. Clean Up (Remove installed UniFi Controller packages)"
echo "4. Cancel"
echo -e "5. Help\n"
read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        install_unifi_apt
        ;;
    2)
        install_unifi_manual
        ;;
    3)
        cleanup_unifi
        ;;
    4)
        echo "Installation canceled."
        exit 0
        ;;
    5)
        echo "Help:"
        echo "1. Install via apt: Installs UniFi Controller using the official repository."
        echo "2. Install custom version: Allows you to choose a custom version and update the UniFi Controller by downloading and manually installing the .deb package."
        echo "3. Clean Up: Removes installed UniFi Controller packages and files."
        echo "4. Cancel: Exits the installation process without making any changes."
        echo "5. Help: Displays this help message."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
