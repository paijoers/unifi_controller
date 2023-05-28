#!/bin/bash
# @nys.pjr 
# Tested OS: Armbian 20.10 (Ubuntu Bionic) & Armbian 21.08.1 (Ubuntu Focal)

install_rng_tools() {
    rngtools_packages=$(dpkg -l | grep rng-tools | awk '{ print $2 }')
    # Check if there are rng-tools packages installed
    if [[ -n $rngtools_packages ]]; then
        echo "rng-tools already installed..."
    else
        echo "Installing rng-tools.."
        sudo apt-get update
        sudo apt-get install -y rng-tools
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
    fi
}

install_unifi_apt() {
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50
    wget -O - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    echo "deb https://www.ui.com/downloads/unifi/debian stable ubiquiti" | sudo tee /etc/apt/sources.list.d/unifi.list
    sudo apt-get update
    install_rng_tools
    sudo apt-get install -y unifi
    sudo apt-get install -fy
    
    # Start UniFi Controller service
    if sudo systemctl start unifi; then
       echo "UniFi Controller service started successfully."
       # Enable UniFi Controller service at boot
       if sudo systemctl enable unifi; then
          echo "UniFi Controller service enabled successfully."
       else
          echo "Failed to enable UniFi Controller service at boot."
       fi
    else
       echo "Failed to start UniFi Controller service."
    fi
}

# Function to install UniFi Controller manually
install_unifi_manual() {
    read -p "Enter the UniFi Controller version you want to install (e.g., 7.3.83): " version
    download_url="https://dl.ui.com/unifi/$version/unifi_sysvinit_all.deb"
    response=$(curl -s -o /dev/null -I -w "%{http_code}" $download_url)
    if [[ $response -eq 200 ]]; then
        sudo rm /etc/apt/sources.list.d/unifi*
        wget -O - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
        echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
        sudo apt-get update
        
        # Download UniFi Controller package
        if [ -f unifi_sysvinit_all.deb ]; then
           echo "Previous UniFi Controller package found. Removing..."
           rm unifi_sysvinit_all.deb
        fi
        echo "Downloading UniFi Controller package..."
        wget -O unifi_sysvinit_all.deb $download_url
        
        # Install UniFi Controller package
        sudo dpkg -i unifi_sysvinit_all.deb
        sudo apt-get install -fy
        
        # Start UniFi Controller service
        if sudo systemctl start unifi; then
           echo "UniFi Controller service started successfully."
           # Enable UniFi Controller service at boot
           if sudo systemctl enable unifi; then
              echo "UniFi Controller service enabled successfully."
           else
              echo "Failed to enable UniFi Controller service at boot."
           fi
        else
           echo "Failed to start UniFi Controller service."
        fi
    else
        echo "Invalid or unavailable UniFi Controller version. Installation aborted."
    fi
}

cleanup_unifi() {
    java_packages=$(dpkg --list | grep 'openjdk\|oracle-java' | awk '{ print $2 }')
    unifi_packages=$(dpkg --list | grep unifi | awk '{ print $2 }')

    if [[ -n $java_packages ]]; then
        echo "Removing Java packages..."
        sudo apt-get purge -y $java_packages
        sudo apt-get autoremove -y
    else
        echo "No Java packages found."
    fi

    if [[ -n $unifi_packages ]]; then
        echo "Stopping UniFi Controller service..."
        sudo systemctl stop unifi
        echo "Removing UniFi Controller packages..."
        sudo apt-get purge -y $unifi_packages
        sudo apt-get autoremove -y
    else
        echo "No UniFi Controller packages found."
    fi

    echo "Cleanup completed."
}

# Main menu
echo "UniFi Controller Installation Script"
echo "----------------------------------"
echo "1. Install UniFi Controller (APT)"
echo "2. Install UniFi Controller (Manual)"
echo "3. Cleanup UniFi Controller"
echo "4. Exit"
read -p "Enter your choice (1-4): " choice

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
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
