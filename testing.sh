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

        # Set Java path
        export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
        export PATH=$PATH:$JAVA_HOME/bin

        # Install UniFi Controller
        sudo apt install -y unifi
        ;;
    2)
        read -p "Enter the UniFi Controller version you want to install (e.g., 7.3.83): " version

        # Construct the download URL
        download_url="https://dl.ui.com/unifi/$version/unifi_sysvinit_all.deb"

        # Check if the URL is valid
        response_code=$(curl -s --head -w "%{http_code}" "$download_url" -o /dev/null)

        if [[ $response_code == 200 ]]; then
            echo "URL is valid. Downloading UniFi Controller..."
            
            # Check if unifi_sysvinit_all.deb file exists
            if [ -f unifi_sysvinit_all.deb ]; then
                rm unifi_sysvinit_all.deb
            fi

            # Download UniFi Controller with the specified version
            wget -c "$download_url"

            # Install dependencies
            sudo apt install -y openjdk-11-jre-headless mongodb

            # Set Java path
            export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
            export PATH=$PATH:$JAVA_HOME/bin

            # Install UniFi Controller from downloaded package
            sudo dpkg -i unifi_sysvinit_all.deb

            # Install dependencies
            sudo apt install -f -y
        else
            echo "URL is invalid or not accessible. Aborting installation."
            exit 1
        fi
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
