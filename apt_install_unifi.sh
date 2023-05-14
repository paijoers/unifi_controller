#!/bin/bash

# Menambahkan repositori UniFi ke sistem Debian
echo 'deb http://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list

# Menambahkan kunci GPG untuk repositori
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg

# Memperbarui daftar paket
sudo apt update

# Menginstal UniFi Controller
sudo apt install unifi

# Memulai UniFi Controller
sudo systemctl start unifi
