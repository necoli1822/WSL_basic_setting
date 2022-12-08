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
sudo apt install -y coreutils build-essential libcurl4-openssl-dev libxml2-dev zip parallel axel

# Step 5. Download and install Mambaforge
cd ~
echo "Downloading mambaforge."
axel -a -n4 "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
bash Mambaforge-$(uname)-$(uname -m).sh
rm Mambaforge-Linux-x86_64.sh

# Step 6. Building R by using Mamba
$(echo ~)/mambaforge/condabin/mamba install -y R radian

# Step 7. Run R and install required libraries
echo """
chooseCRANmirror(ind=53)
install.packages(\"BiocManager\")
BiocManager::install(c(\"pathview\", \"DESeq2\", \"biomaRt\"), suppressUpdates=TRUE)
require(\"pathview\", quietly = TRUE)
require(\"DESeq2\", quietly = TRUE)
require(\"biomaRt\", quietly = TRUE)
q()
""" | $(echo ~)/mambaforge/bin/radian --vanilla --no-save -q --r-binary $(echo ~)/mambaforge/bin/R

# Step 8. Download and install STAR aligner and RSEM tools
echo "Downloading STAR aligner"
axel -a -n4 "https://github.com/alexdobin/STAR/releases/download/2.7.10b/STAR_2.7.10b.zip"
unzip STAR_2.7.10b.zip
rm STAR_2.7.10b.zip
sudo mkdir /usr/local/bin/STAR
sudo mv STAR_2.7.10b/Linux_x86_64_static/STAR* /usr/local/bin/STAR/
sudo chmod +x /usr/local/bin/STAR*
echo "export PATH=\"/usr/local/bin/STAR\":\$PATH" >> ~/.bashrc
rm -rf STAR_2.7.10b
echo "Downloading RSEM"
wget -qO- "https://github.com/deweylab/RSEM/archive/refs/tags/v1.3.3.tar.gz" | tar zxvf -
cd RSEM-1.3.3/
ls | grep rsem | parallel sudo chmod +x
cd ../
sudo mv RSEM-1.3.3/ /usr/local/bin/
echo "export PATH=\"/usr/local/bin/RSEM-1.3.3\":\$PATH" >> ~/.bashrc
source ~/.bashrc
echo "Every steps are finished. Report me when there is an error."


exit 0
