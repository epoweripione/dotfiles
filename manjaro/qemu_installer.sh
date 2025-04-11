#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

# KVM & QEMU
colorEcho "${BLUE}Installing ${FUCHSIA}swtpm${BLUE}..."
sudo pacman --noconfirm --needed -S --asdeps swtpm # TPM Emulator

InstallList=(
    "edk2-ovmf" # Enable secure-boot/UEFI on KVM
    "vde2"
    "bridge-utils"
    "openbsd-netcat"
    "dnsmasq"
    "ebtables"
    # "iptables-nft"
    "iptables"
    "dpkg"
    "guestfs-tools"
    "libguestfs"
    "libvirt"
    "qemu-desktop"
    "qemu-efi-aarch64"
    "qemu-system-aarch64"
    "qemu-system-arm-firmware"
    "virt-install"
    "virt-manager"
    "virt-viewer"
    "virtio-win"
)
InstallSystemPackages "" "${InstallList[@]}"

## Run and enable boot up start libvirtd daemon
# sudo systemctl enable libvirtd.service
# sudo systemctl start libvirtd.service
sudo systemctl enable --now libvirtd.service

# Enable normal user account to use KVM
if [[ -f "/etc/libvirt/libvirtd.conf" ]]; then
    sudo sed -i 's/^[# ]*unix_sock_group.*/unix_sock_group = "libvirt"/g' "/etc/libvirt/libvirtd.conf"
    sudo sed -i 's/^[# ]*unix_sock_rw_perms.*/unix_sock_rw_perms = "0770"/g' "/etc/libvirt/libvirtd.conf"
fi

## Add user to the kvm and libvirt groups
# sudo usermod -a -G libvirt "$(whoami)"
# newgrp libvirt
sudo gpasswd -a "$(whoami)" kvm
sudo gpasswd -a "$(whoami)" libvirt

sudo systemctl restart libvirtd.service

# Enable Nested Virtualization (Optional)
CPU_VENDOR=$(lscpu | grep Vendor | awk '{print $NF}')
if grep -q 'Intel' <<<"${CPU_VENDOR}"; then
    # Intel Processor
    echo "options kvm_intel nested=1" | sudo tee "/etc/modprobe.d/kvm_intel.conf" >/dev/null
elif grep -q 'AMD' <<<"${CPU_VENDOR}"; then
    # AMD Processor
    echo "options kvm_amd nested=1" | sudo tee "/etc/modprobe.d/kvm_amd.conf" >/dev/null
fi

# Marked network default as autostarted
sudo virsh net-autostart default
sudo virsh net-start default

cd "${CURRENT_DIR}" || exit
