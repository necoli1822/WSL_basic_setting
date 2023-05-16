#!/usr/bin/env bash

#Run this script to build environment.
#Firstly install Windows subsystem Linux following the link below.
#https://learn.microsoft.com/ko-kr/windows/wsl/install

# Step 1. Super-user password assign
echo "Set your super-user password."
sudo passwd

# Step 2. Replace apt source with Daum Kakao
sudo sed -i 's/archive\.ubuntu\.com/mirror\.kakao\.com/g' /etc/apt/sources.list

# Step 3. Update and upgrade your system using APT
echo "Updating and upgrading the system."
sudo apt update && sudo apt upgrade -y

# Step 4. Install default dependent packages from APT
echo "Installing basic packages."
sudo apt install -y coreutils build-essential libcurl4-openssl-dev libxml2-dev zip parallel axel perl-doc

# Step 5. Download and install Mambaforge
cd ~
echo "Downloading mambaforge."
axel -a -n4 "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
bash Mambaforge-$(uname)-$(uname -m).sh
rm Mambaforge-Linux-x86_64.sh


exit 0
