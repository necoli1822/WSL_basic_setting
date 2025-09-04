#/usr/bin/env bash

# rough, dirty coding but still works
# it is not including a step to check dependencies such as build-essentials

# getting the lastest version from GitHub
get_latest_version(){
        if [[ $1 == "https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/" ]]; then
                wget -qO- https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ | grep -oP ">ncbi-blast-.*\+" | head -1 | sed 's/>ncbi-blast-\(.*\)+/\1/g'
        else
                wget -O /dev/null $1"/releases/latest" 2>&1 | grep -w 'Location' | cut -d" " -f2 | awk -F"/" '{print $NF}'
        fi
}


# ask proceeding
read -p "You finally decided to UPDATE? [y/N]: " yn && [[ ${yn^^} == 'Y' ]] || exit


declare -A tools down_links versions


# read the /usr/local/bin/README.md, which is a csv consist of tool name and github or download link; need to add a column to indicate an exception for tools not maintained by GitHub such as NCBI

# example of the README.md

<<example
# List of tools under auto-update
Bracken,https://github.com/jenniferlu717/Bracken
Kraken2,https://github.com/DerrickWood/kraken2
SPAdes,https://github.com/ablab/spades
bcftools,https://github.com/samtools/bcftools
bwa-mem2,https://github.com/bwa-mem2/bwa-mem2
htslib,https://github.com/samtools/htslib
mash,https://github.com/marbl/Mash
minimap2,https://github.com/lh3/minimap2
mmseqs,https://github.com/soedinglab/MMseqs2
ncbi-blast,https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST
samtools,https://github.com/samtools/samtools
iqtree3,https://github.com/iqtree/iqtree3
example

echo ""
echo "Read the tool list from /usr/local/bin/README.md"
while IFS="," read -r -a l; do
        if [[ $l != \#* ]]; then
                if [[ $l[0] != "ncbi-blast" ]]; then
                        tools[${l[0]}]=${l[1]}
                fi
        else
                :
        fi
done < /usr/local/bin/README.md


# assign blast ftp location
tools["ncbi-blast"]="https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/"


# get latest versions
echo ""
echo "Getting the latest versions..."
echo ""

for id in "${!tools[@]}"; do
    echo "Loading "${id}" version"
        versions[$id]=$(get_latest_version "${tools[$id]}")
done


# make download links
for id in "${!tools[@]}"; do
        case $id in
                "ncbi-blast")
                        down_links["ncbi-blast"]=${tools["ncbi-blast"]}ncbi-blast-${versions[ncbi-blast]}+-x64-linux.tar.gz
                        ;;
                "mmseqs")
                        down_links[mmseqs]="https://github.com/soedinglab/MMseqs2/releases/download/${versions[mmseqs]}/mmseqs-linux-avx2.tar.gz"
                        ;;
                "htslib" | "samtools" | "bcftools")
                        down_links[$id]=$(echo "${tools[$id]}" | awk -v version="${versions[$id]}" -v id="$id" -F"/" '{print $0 "/releases/download/" version "/" id "-" version ".tar.bz2"}' OFS="/" ORS="")
                        ;;
                "mash")
                        down_links[$id]="https://github.com/marbl/Mash/releases/download/"${versions[mash]}"/mash-Linux64-"${versions[mash]}".tar"
                        ;;
                "bwa-mem2")
                        down_links[$id]="https://github.com/bwa-mem2/bwa-mem2/releases/download/"${versions[$id]}"/bwa-mem2-"${versions[$id]#v}"_x64-linux.tar.bz2"
                        ;;
                "iqtree3")
                        down_links[$id]="https://github.com/iqtree/iqtree3/releases/download/"${versions[$id]}"/iqtree-"${versions[$id]#v}"-Linux.tar.gz"
                        ;;
                *)
                        down_links[$id]=$(echo "${tools[$id]}" | awk -v version="${versions[$id]}" -F"/" '{print $0 "/archive/refs/tags/" version ".tar.gz"}' OFS="/" ORS="")
                        ;;
        esac
done


# make directories; update dir will contain the source files
for dir in "${!tools[@]}"; do
        if [[ -d $dir/update ]]; then
                :
        else
                mkdir -p ./${dir}/update
        fi
done


# check latest version
for id in "${!tools[@]}"; do
        if [[ -d $id/${id}_${versions[$id]} ]]; then
                unset tools[$id]
        fi
done


# show the update list
echo ""
echo "These tools will be updated."
echo ""
printf "%s %s\n" "------------" "----------------"
printf "Name         Updating Version\n"
printf "%s %s\n" "------------" "----------------"
for id in "${!tools[@]}"; do
        printf "%-12s %-16s\n" ${id} ${versions[$id]}
done
printf "%s %s\n" "------------" "----------------"
echo ""

read -p "Do you want to update those tools? [y/N]: " yn && [[ ${yn^^} == 'Y' ]] || exit


# download the files
echo ""
echo "Start downloading..."
for id in "${!tools[@]}"; do
        case ${id} in
                "ncbi-blast")
                        wget -q -P ./ncbi-blast/update/ ${down_links[ncbi-blast]} 2>&1 &
                        ;;
                "mmseqs") # since there's no version
                        wget -q -O ./mmseqs/update/mmseqs-${versions[mmseqs]}-linux-avx2.tar.gz ${down_links[mmseqs]} 2>&1 &
                        ;;
                *)
                        wget -q -P ./${id}/update/ ${down_links[$id]} 2>&1 &
                        ;;
                esac
done

echo "Waiting for downloads to be done..."
wait
echo "All downloads are now finished."

# uncompress the files and check whether it is the latest verison
echo ""
echo "Uncompressing the files..."
for i in ${!tools[@]}; do
        case $i in
                "ncbi-blast")
                        mkdir -p ${i}/${i}_${versions[$i]} && tar zxf ${i}/update/ncbi-blast-${versions[$i]}+-x64-linux.tar.gz -C ${i}/${i}_${versions[$i]} --strip-components=1 &
                        ;;
                "mmseqs")
                        mkdir -p ${i}/${i}_${versions[$i]} && tar zxf ${i}/update/mmseqs-${versions[mmseqs]}-linux-avx2.tar.gz -C ${i}/${i}_${versions[$i]} --strip-components=1 &
                        ;;
                "samtools" | "bcftools" | "htslib")
                        mkdir -p ${i}/${i}_${versions[$i]} && tar xf ${i}/update/${i}-${versions[$i]}.tar.bz2 -C ${i}/${i}_${versions[$i]} --strip-components=1 &
                        ;;
                "mash")
                        mkdir -p ${i}/${i}_${versions[$i]} && tar xf ${i}/update/mash-Linux64-${versions[$i]}.tar -C ${i}/${i}_${versions[$i]} --strip-components=1 &
                        ;;
                "bwa-mem2")
                        mkdir -p ${i}/${i}_${versions[$i]} && tar xf ${i}/update/bwa-mem2-${versions[$i]#v}_x64-linux.tar.bz2 -C ${i}/${i}_${versions[$i]} --strip-components=1 &
                        ;;
                "iqtree3")
                        mkdir -p ${i}/${i}_${versions[$i]} && tar xf ${i}/update/iqtree-${versions[$i]#v}-Linux.tar.gz -C ${i}/${i}_${versions[$i]} --strip-components=1 &
                        ;;
                *)
                        mkdir -p ${i}/${i}_${versions[$i]} && tar zxf ${i}/update/${versions[$i]}.tar.gz -C ${i}/${i}_${versions[$i]} --strip-components=1 &
                        ;;
        esac
done

echo "Waiting for decompression to be done..."
wait
echo "All files are now decompressed."

### compiling
echo ""
echo "Now compiling and making the symlink for the latest version..."
echo "This step will take a lot of time - go get a coffee."
echo ""
for i in ${!tools[@]}; do
        case $i in
                "ncbi-blast")
                        cd ${i}
                        ln -sfT ${i}_${versions[$i]} latest
                        cd ../
                        ;;
                "mmseqs")
                        cd ${i}
                        ln -sfT ${i}_${versions[$i]} latest
                        cd ../
                        ;;
                "bwa-mem2")
                        cd ${i}
                        ln -sfT ${i}_${versions[$i]} latest
                        cd ../
                        ;;
                "samtools" | "bcftools" | "htslib")
                        cd ${i}/${i}_${versions[$i]}
                        ./configure
                        make -j$(nproc)
                        cd ../
                        ln -sfT ${i}_${versions[$i]} latest
                        cd ../
                        ;;
                "Kraken2")
                        cd ${i}/${i}_${versions[$i]}
            sed -i "s/make -C/make -j$(nproc) -C/g" install_kraken2.sh
                        ./install_kraken2.sh ./
                        cd ../
                        ln -sfT ${i}_${versions[$i]} latest
                        cd ../
                        ;;
                "minimap2")
                        cd ${i}/${i}_${versions[$i]}
                        make
                        cd ../
                        ln -sfT ${i}_${versions[$i]} latest
                        cd ../
                        ;;
                "SPAdes")
                        cd ${i}/${i}_${versions[$i]}
                        ./spades_compile.sh -j$(nproc) -a
                        cd ../
                        ln -sfT ${i}_${versions[$i]} latest
                        cd ../
                        ;;
                *)
                        cd ${i}
                        ln -sfT ${i}_${versions[$i]} latest
                        cd ../
        esac
done

echo ""
echo ""
echo "All processes are done."
echo "Run or add the following command at the end of ~/.bashrc."
echo 'export PATH="$(/usr/bin/find /usr/local/bin -maxdepth 2 -iname "*latest" -type l -exec realpath {} \; | paste -s -d:)":$PATH'
echo "If the tools are not running, check the directories and PATH global variable."
