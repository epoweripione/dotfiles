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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

USBDISK=${1:-"sdb1"}
[[ ! -d "/mnt/${USBDISK}" && -b "/dev/${USBDISK}" ]] && mkdir "/mnt/${USBDISK}" && mount -o rw,noatime "/dev/${USBDISK}" "/mnt/${USBDISK}"

[[ -d "/mnt/${USBDISK}" ]] && WRT_WORKDIR="/mnt/${USBDISK}" || WRT_WORKDIR="/tmp"

## OpenWrt A/B Upgrades
## https://github.com/pyther/openwrt-sysupgrade-ab
# opkg install blkid cfdisk coreutils-stat e2fsprogs fdisk

# PROXY_ADDRESS="http://localhost:7890" && export {http,https,ftp,all}_proxy="${PROXY_ADDRESS}" && export {HTTP,HTTPS,FTP,ALL}_PROXY="${PROXY_ADDRESS}"

# KERNEL_URL="https://downloads.openwrt.org/snapshots/targets/x86/64/openwrt-x86-64-generic-kernel.bin"
# ROOTFS_URL="https://downloads.openwrt.org/snapshots/targets/x86/64/openwrt-x86-64-rootfs.tar.gz"

# https://github.com/SuLingGG/OpenWrt-Rpi
KERNEL_URL="https://openwrt.cc/releases/targets/x86/64/openwrt-x86-64-generic-kernel.bin"
ROOTFS_URL="https://openwrt.cc/releases/targets/x86/64/openwrt-x86-64-generic-rootfs.tar.gz"

curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WRT_WORKDIR}/upgrade.sh" \
    "https://github.com/pyther/openwrt-sysupgrade-ab/raw/master/upgrade.sh" && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WRT_WORKDIR}/openwrt-x86-64-generic-kernel.bin" "${KERNEL_URL}" && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WRT_WORKDIR}/openwrt-x86-64-rootfs.tar.gz" "${ROOTFS_URL}"

if [[ -s "${WRT_WORKDIR}/upgrade.sh" && -s "${WRT_WORKDIR}/openwrt-x86-64-generic-kernel.bin" && -s "${WRT_WORKDIR}/openwrt-x86-64-rootfs.tar.gz" ]]; then
    BOOT_DEV=${1:-"/dev/sda1"} && ROOTA_DEV=${2:-"/dev/sda2"} && ROOTB_DEV=${3:-"/dev/sda3"}

    sed -e "s|^BOOT_DEV=.*|BOOT_DEV=\"${BOOT_DEV}\"|" \
        -e "s|^ROOTA_DEV=.*|ROOTA_DEV=\"${ROOTA_DEV}\"|" \
        -e "s|^ROOTB_DEV=.*|ROOTB_DEV=\"${ROOTB_DEV}\"|" \
        -i "${WRT_WORKDIR}/upgrade.sh"

    if ! findmnt "/boot" 2>/dev/null; then
        mkdir -p "/boot" && \
            mount -o rw,noatime "/dev/${BOOT_DEV}" "/boot" && \
            mount --bind "/boot/boot" "/boot"
        # mkdir -p "/tmp/boot" && \
        #     mount -o rw,noatime "/dev/${BOOT_DEV}" "/tmp/boot" && \
        #     ln -s "/tmp/boot/boot" "/boot"
    fi

    GRUB_FILE="/boot/grub/grub.cfg"
    if grep -q "(hd0,gpt1)" "${GRUB_FILE}" 2>/dev/null; then
        sed -e 's|(hd0,msdos1)|(hd0,gpt1)|g' \
            -e 's|linux (hd0,msdos${partid})/vmlinuz|linux /boot/vmlinuz|g' \
            -e 's|linux (hd0,msdos${a_partid})/vmlinuz|linux /boot/vmlinuz.old|g' \
            -i "${WRT_WORKDIR}/upgrade.sh"
    fi

    cd "${WRT_WORKDIR}" && chmod +x "${WRT_WORKDIR}/upgrade.sh" && \
        ./upgrade.sh openwrt-x86-64-generic-kernel.bin openwrt-x86-64-rootfs.tar.gz && \
        cp -f "/boot/vmlinuz" "/boot/vmlinuz.old" && \
        cp -f openwrt-x86-64-generic-kernel.bin "/boot/vmlinuz" && \
        echo 'ok' > "/restore.ok"
fi

# reboot

cd "${CURRENT_DIR}" || exit
