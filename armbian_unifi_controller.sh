#!/bin/bash
# @nys.pjr 
# Tested OS: Armbian 20.10 Ubuntu Bionic

install_unifi_apt() {
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50
    wget -O - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    echo "deb https://www.ui.com/downloads/unifi/debian stable ubiquiti" | sudo tee /etc/apt/sources.list.d/unifi.list
    sudo apt update
    sudo apt install -y openjdk-11-jre-headless
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-$(dpkg --print-architecture)
    export PATH=$PATH:$JAVA_HOME/bin
    sudo apt install -y unifi
    sudo apt install -y rng-tools
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
    sudo systemctl start unifi
    sudo systemctl enable unifi
    echo "UniFi Controller has been installed and started."
}

# Function to install UniFi Controller manually
install_unifi_manual() {
    # Check if unifi_sysvinit_all.deb file exists
    if [ -f unifi_sysvinit_all.deb ]; then
      echo "Previous UniFi Controller package found. Removing..."
      rm unifi_sysvinit_all.deb
    fi

    read -p "Enter the UniFi Controller version you want to install (e.g., 7.3.83): " version
    download_url="https://dl.ui.com/unifi/$version/unifi_sysvinit_all.deb"
    response=$(curl -s -o /dev/null -I -w "%{http_code}" $download_url)
    if [[ $response -eq 200 ]]; then
        # Download UniFi Controller package
        wget -c $download_url -O unifi_sysvinit_all.deb
        
        # Install dependencies (Java and MongoDB)
        if [[ "$version" < "7.3" ]]; then
            # Install Java 8
            sudo apt install -y openjdk-8-jre-headless
        else
            # Install Java 11
            sudo apt install -y openjdk-11-jre-headless
        fi
        
        # Install MongoDB
        wget -O - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
        echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
        sudo apt update
        sudo apt install -y mongodb-org

        # Install UniFi Controller
        sudo dpkg -i unifi_sysvinit_all.deb
        sudo apt install -fy
        
        # Install rng-tools
        sudo apt install -y rng-tools
        if grep -q "^HRNGDEVICE=" /etc/default/rng-tools; then
           # Replace the line with the new value
           sudo sed -i "s|^HRNGDEVICE=.*|HRNGDEVICE=/dev/urandom|" /etc/default/rng-tools
        else
           # Add the line if it doesn't exist
           sudo echo "HRNGDEVICE=/dev/urandom" | sudo tee -a /etc/default/rng-tools
        fi
        sudo systemctl stop haveged
        sudo systemctl disable haveged
        sudo systemctl start unifi
        sudo systemctl enable unifi
        echo "UniFi Controller has been installed and started."
    else
        echo "URL is invalid or not accessible. Aborting installation."
        exit 1
    fi
}


# Function to clean up UniFi Controller
cleanup_unifi() {
    read -p "Do you want to remove Java as well? (y/n): " remove_java
    if [[ $remove_java == "y" ]]; then
        sudo apt purge -y openjdk*
        sudo apt autoremove -y
    fi

    sudo apt purge -y unifi
    sudo apt autoremove -y
    sudo rm -rf /usr/lib/unifi
    sudo rm -rf /var/lib/unifi
    sudo rm -rf /var/log/unifi
    sudo rm -rf /var/run/unifi
    sudo rm -rf /etc/unifi
    sudo rm /etc/apt/sources.list.d/mongodb-org-\*
    sudo rm /etc/apt/sources.list.d/unifi.list
    sudo systemctl enable haveged
    sudo systemctl start haveged
    sudo apt purge -y rng-tools
    sudo apt autoremove
    echo "UniFi Controller has been successfully removed."
    exit 0
}

# Show menu and ask for user input
echo -e "\nUniFi Controller Installation"
echo -e "---------------------------\n"
echo "1. Install UniFi Controller via apt"
echo "2. Manual Install (Install UniFi Controller without using apt)"
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
        echo "1. Install UniFi Controller via apt: Installs UniFi Controller using the official repository."
        echo "2. Manual Install: Allows you to update UniFi Controller by downloading and manually installing the .deb package."
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
