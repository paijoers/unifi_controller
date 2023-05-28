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
        sudo apt-get install -y rng-tools
        if grep -q "^HRNGDEVICE=" /etc/default/rng-tools; then
           # Replace the line with the new value
           sudo sed -i "s|^HRNGDEVICE=.*|HRNGDEVICE=/dev/urandom|" /etc/default/rng-tools
        else
           # Add the line if it doesn't exist
           sudo echo "HRNGDEVICE=/dev/urandom" | sudo tee -a /etc/default/rng-tools
        fi
        sudo systemctl restart rng-tools
        sudo systemctl stop haveged
        sudo systemctl disable haveged
    fi
}

install_unifi_apt() {
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50
    sudo wget -O - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
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
        sudo wget -O - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
        echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
        sudo apt-get update
        
        # Download UniFi Controller package
        if [ -f unifi_sysvinit_all.deb ]; then
           echo "Previous UniFi Controller package found. Removing..."
           sudo rm unifi_sysvinit_all.deb
        fi
        wget -c $download_url -O unifi_sysvinit_all.deb
        
        # Install dependencies (Java and MongoDB)
        if [[ "$version" < "7.3.76" ]]; then
            # Install Java 8
            sudo apt-get install -y openjdk-8-jre-headless
            export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-$(dpkg --print-architecture)
            export PATH=$PATH:$JAVA_HOME/bin
        else
            # Install Java 11
            sudo apt-get install -y openjdk-11-jre-headless
            export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-$(dpkg --print-architecture)
            export PATH=$PATH:$JAVA_HOME/bin
        fi
        
        # Check if there are MongoDB packages installed
        mongodb_packages=$(dpkg -l | grep mongodb | awk '{ print $2 }')
        # Get the list of installed MongoDB packages
        if [[ -n $mongodb_packages ]]; then
           echo "Mongodb already installed"
           sudo apt-get install -y mongodb
        else
           echo "Installing MongoDB.."
           sudo apt-get install -y mongodb
        fi

        # Install UniFi Controller
        sudo dpkg -i unifi_sysvinit_all.deb
        install_rng_tools
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
       echo "Invalid version or Link not found. Aborting installation."
       exit 1
     fi
}


# Function to clean up UniFi Controller
cleanup_unifi() {
    # Stop UniFi Controller service
    echo -e "Stopping unifi services..\n"
    sudo systemctl stop unifi
    sudo systemctl disable unifi

    # Remove java
    read -p "Do you want to remove Java as well? (y/n): " remove_java
    if [[ $remove_java == "y" ]]; then
        java_packages=$(dpkg --list | grep jdk | awk '{ print $2 }')
        if [[ -n $java_packages ]]; then
            echo "Uninstalling Java packages..."
            sudo apt-get remove --purge -y $java_packages
            sudo apt-get autoremove -y
        else
            echo "No Java packages installed."
        fi
    fi
    
    read -p "Do you want to remove mongodb as well? (y/n): " remove_mongodb
    if [[ $remove_mongodb == "y" ]]; then
    # Check if there are MongoDB packages installed
    mongodb_packages=$(dpkg -l | grep mongodb | awk '{ print $2 }')
    # Get the list of installed MongoDB packages
    if [[ -n $mongodb_packages ]]; then
        echo "Uninstalling MongoDB packages..."
        # Remove MongoDB packages
        sudo systemctl stop mongodb
        sudo rm /etc/apt/sources.list.d/mongodb*
        sudo apt-get remove --purge -y $mongodb_packages
    else
        echo "No MongoDB packages installed."
    fi
    fi
    
    read -p "Do you want to remove rng-tools as well? (y/n): " remove_rngtools
    if [[ $remove_rngtools == "y" ]]; then
    # Get the list of installed rng-tools packages
    rngtools_packages=$(dpkg -l | grep rng-tools | awk '{ print $2 }')
    # Check if there are rng-tools packages installed
    if [[ -n $rngtools_packages ]]; then
        # Enable haveged service to generate random numbers
        echo "Enable haveged service"
        sudo systemctl enable haveged
        sudo systemctl start haveged
        # Remove rng-tools packages
        echo "Uninstalling rng-tools packages..."
        sudo apt-get remove --purge -y $rngtools_packages
    else
        echo "No rng-tools packages installed."
    fi
    fi

    # Get the list of installed UniFi Controller packages
    unifi_packages=$(dpkg -l | grep unifi | awk '{ print $2 }')
    # Check if there are UniFi Controller packages installed
    if [[ -n $unifi_packages ]]; then
        echo "Uninstalling UniFi Controller packages..."
        # Remove UniFi Controller packages
        sudo rm /etc/apt/sources.list.d/unifi*
        sudo apt-get remove --purge -y $unifi_packages
    else
        echo "No UniFi Controller packages installed."
    fi

    # Clean up unused packages
    sudo apt-get autoremove -y

    exit 0
}

# Show menu and ask for user input
echo -e "\n-- UniFi Controller Installation --\n"
echo "1. Install via apt"
echo "2. Install custom version"
echo "3. Uninstall"
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
        echo "3. Uninstall: Removes installed UniFi Controller packages and files."
        echo "4. Cancel: Exits the installation process without making any changes."
        echo "5. Help: Displays this help message."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
