#/usr/bin/env bash
# run all commands as su
sudo apt install podman qemu-system-x86 gvproxy
sudo ln -s /usr/bin/gvproxy /usr/libexec/podman/
sudo chmod 666 /dev/kvm
# the following is just for convenience
sudo sed -i '21 c\unqualified-search-registries = ["docker.io"]' /etc/containers/registries.conf
