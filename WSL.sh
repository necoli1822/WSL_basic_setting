#!/usr/bin/env bash

###
Run this script to build environment.
Firstly install Windows subsystem Linux following the link below.
https://learn.microsoft.com/ko-kr/windows/wsl/install
###

# Step 1. Super-user password assign
echo "Set your super-user password."
sudo passwd

# Step 2. Update and upgrade your system using APT
echo "Updating and upgrading the system."
sudo apt update && sudo apt upgrade -y

# Step 3. Install default dependent packages from APT
echo "Installing basic packages."
sudo apt install –y coreutils build-essential libcurl4-openssl-dev libxml2-dev zip parallel

# Step 4. Download and install Mambaforge
cd ~
forge_version="$(wget -O- "https://github.com/conda-forge/miniforge/releases/latest" | grep -oP "conda-forge/miniforge/releases/tag/\w.*\" \/>" | sed 's/\".*//g' | sort -u | tail -1 | cut -d"/" -f5)"
echo ${forge_version}
echo "Downloading mambaforge."
wget https://github.com/conda-forge/miniforge/releases/download/${forge_version}/Mambaforge-Linux-x86_64.sh
echo "Installing mambaforge."
bash ~/Miniforge3-Linux-x86_64.sh -b
mamba config --set auto_activate_base true
echo "Mambaforge activation is set to be default."
source ~/.bashrc

# Step 5. Building R by using Mamba
mamba install -y R
mamba install -y radian

# Step 6. Run R and install required libraries
echo """
chooseCRANmirror(ind=53)
install.packages(\"BiocManager\")
BiocManager::install(c(\"pathview\", \"DESeq2\", \"biomaRt\"), suppressUpdates=TRUE)
if (!require(\"pathview\", quietly = TRUE))
  print(\"Pathview is installed.\")
if (!require(\"DESeq2\", quietly = TRUE))
  print(\"DESeq2 is installed.\")
if (!require(\"biomaRt\", quietly = TRUE))
  print(\"BiomaRt is installed.\")
""" | R --no-save

# Step 7. Download and install STAR aligner and RSEM tools
wget -qO- "https://github.com/alexdobin/STAR/releases/download/2.7.10b/STAR_2.7.10b.zip" | bsdtar -xvf-
sudo cp STAR_2.7.10b/Linux_x86_64_static/STAR* /usr/local/bin/
sudo chmod +x /usr/local/bin/STAR*
sudo rm -rf STAR_2.7.10b
wget -qO- "https://github.com/deweylab/RSEM/archive/refs/tags/v1.3.3.tar.gz" | tar zxvf -
sudo mv STAR_2.7.10b/ /usr/local/bin
cd /usr/local/bin/STAR_2.7.10b/
ls | grep rsem | parallel sudo chmod +x
