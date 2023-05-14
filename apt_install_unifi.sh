#!/bin/bash

# Menambahkan repositori UniFi
echo 'deb http://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list

# Menambahkan kunci GPG untuk repositori
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg

# Menambahkan repositori MongoDb
wget -qO - https://www.mongodb.org/static/pgp/server-3.6.asc | sudo apt-key add -
echo "deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/3.6 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list

# Memperbarui daftar paket
sudo apt update

# Menginstall Java 11
sudo apt install openjdk-11-jdk -y

# Menginstall MongoDB
sudo apt install mongodb-org -y

# Menginstal UniFi Controller
sudo apt install unifi -y

# Done!
