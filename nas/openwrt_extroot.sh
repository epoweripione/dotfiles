#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

## Setting up /overlay on other drive
## https://openwrt.org/docs/guide-user/additional-software/extroot_configuration

# cat /etc/config/fstab
# uci show fstab
# cat /etc/mtab
# findmnt

opkg update
opkg install kmod-fs-ext4 kmod-fs-f2fs kmod-fs-ntfs kmod-usb-core kmod-usb-storage kmod-usb-ohci kmod-usb-uhci \
    block-mount f2fs-tools mount-utils pciutils usbutils swap-utils \
    blkid cfdisk dumpe2fs e2fsprogs fdisk lsblk parted resize2fs tune2fs

# Configuring rootfs_data
# grep -e rootfs_data /proc/mtd
# The directory /rwm will contain the original root overlay, 
# which is used as the main root overlay until the extroot is up and running.
# Later you can edit /rwm/upper/etc/config/fstab to change your extroot configuration (or temporarily disable it) should you ever need to.
DEVICE="$(sed -n -e "/\s\/overlay\s.*$/s///p" /etc/mtab)"
if [[ -n "${DEVICE}" ]]; then
    uci -q delete fstab.rwm
    uci set fstab.rwm="mount"
    uci set fstab.rwm.device="${DEVICE}"
    uci set fstab.rwm.target="/rwm"
    uci commit fstab
fi

# Configuring extroot
# block info
# The drive for /overlay
# EXTROOT_DEVICE="/dev/${USBDISK}"
EXTROOT_DEVICE=${1:-""}
if [[ -n "${EXTROOT_DEVICE}" ]]; then
    mkfs.ext4 "${EXTROOT_DEVICE}"
    eval "$(block info "${EXTROOT_DEVICE}" | grep -o -e "UUID=\S*")"
    uci -q delete fstab.overlay && \
        uci set fstab.overlay="mount" && \
        uci set fstab.overlay.uuid="${UUID}" && \
        uci set fstab.overlay.target="/overlay" && \
        uci commit fstab

    # Transferring data
    mkdir -p /tmp/cproot && \
        mount --bind /overlay /tmp/cproot && \
        mount "${EXTROOT_DEVICE}" /mnt && \
        tar -C /tmp/cproot -cvf - . | tar -C /mnt -xf -	 && \
        umount /tmp/cproot /mnt && \
        reboot
fi

## Swap
## If your device fails to read the lists due to small RAM such as 32MB, enable swap.
## Create swap file
# dd if=/dev/zero of=/overlay/swap bs=1M count=100
# mkswap /overlay/swap
## Enable swap file
# uci -q delete fstab.swap
# uci set fstab.swap="swap"
# uci set fstab.swap.device="/overlay/swap"
# uci commit fstab
# /etc/init.d/fstab boot
## Verify swap status
# cat /proc/swaps

## Fix: Read-only file system
# mount -o remount rw /

## mount USB drive
USBDISK=${1:-"sdb1"}
if [[ ! -d "/mnt/${USBDISK}" && -b "/dev/${USBDISK}" ]]; then
    mkdir -p "/mnt/${USBDISK}"
    mount -o rw,noatime "/dev/${USBDISK}" "/mnt/${USBDISK}"
    sed -i "/^exit 0/i mount -o rw,noatime /dev/${USBDISK} /mnt/${USBDISK}" /etc/rc.local
fi

cd "${CURRENT_DIR}" || exit
