#!/usr/bin/env bash

# Step 6. Building R by using Mamba
mamba install -y R radian

# Step 7. Run R and install required libraries
echo """
chooseCRANmirror(ind=53)
install.packages(\"BiocManager\")
BiocManager::install(c(\"pathview\", \"DESeq2\", \"biomaRt\"), suppressUpdates=TRUE)
require(\"pathview\", quietly = TRUE)
require(\"DESeq2\", quietly = TRUE)
require(\"biomaRt\", quietly = TRUE)
q()
""" | radian --vanilla --no-save -q

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
