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

USBDISK=${1:-"sdb1"}
[[ ! -d "/mnt/${USBDISK}" && -b "/dev/${USBDISK}" ]] && mkdir "/mnt/${USBDISK}" && mount -o rw,noatime "/dev/${USBDISK}" "/mnt/${USBDISK}"

[[ -d "/mnt/${USBDISK}" ]] && WRT_WORKDIR="/mnt/${USBDISK}" || WRT_WORKDIR="/tmp"
[[ -d "${WRT_WORKDIR}" ]] && OPKG_EXTRAS="${WRT_WORKDIR}/opkg-extras.sh" || OPKG_EXTRAS="$PWD/opkg-extras.sh"

# Saving/restoring user-installed packages
opkg update
opkg install libustream-mbedtls

if [[ ! -s "${OPKG_EXTRAS}" ]]; then
    uclient-fetch -O "${OPKG_EXTRAS}" "https://openwrt.org/_export/code/docs/guide-user/advanced/opkg_extras?codeblock=0"
fi

[[ -s "${OPKG_EXTRAS}" ]] && . "${OPKG_EXTRAS}"

# Save Opkg profile
opkg save

## Roll back Opkg profile
# opkg rollback

## Set up a custom Opkg profile
# uci set opkg.defaults.restore="custom"
# uci -q delete opkg.custom.rpkg
# uci add_list opkg.custom.rpkg="dnsmasq"
# uci add_list opkg.custom.rpkg="ppp"
# uci -q delete opkg.custom.ipkg
# uci add_list opkg.custom.ipkg="curl"
# uci add_list opkg.custom.ipkg="diffutils"
# uci add_list opkg.custom.ipkg="dnsmasq-full"
# uci commit opkg


## Backup
## https://openwrt.org/docs/guide-user/troubleshooting/backup_restore
## Add files/directories
cat << EOF >> /etc/sysupgrade.conf
# /etc/sudoers
# /etc/sudoers.d
/root
EOF

## Verify backup configuration
# sysupgrade -l

# Generate backup
umask go= && \
    BACKUP_FILE="${WRT_WORKDIR}/backup-${HOSTNAME:-openwrt}-$(date +%F).tar.gz" && \
    sysupgrade -b "${BACKUP_FILE}" && \
    ls "${BACKUP_FILE}"
## Download backup
# scp root@openwrt:${BACKUP_FILE} .
# rsync -avz --progress root@openwrt:${BACKUP_FILE} .


## Upgrading OpenWrt firmware using LuCI and CLI
## https://openwrt.org/docs/guide-user/installation/generic.sysupgrade
## https://openwrt.org/docs/guide-user/installation/openwrt_x86
## use Debian LiveCD to upgrade boot partition /boot/vmlinuz & rootfs partition /dev/sda2


## https://blog.csdn.net/sinat_20184565/article/details/105351625
## extract img
# sudo pacman -S binwalk squashfs-tools
# binwalk -e openwrt-x86-64-generic-ext4-combined-efi.img
# cd *.extracted
# [[ -f "1080000.squashfs" ]] && unsquashfs -dest 1080000.extracted 1080000.squashfs

# . /etc/openwrt_release
# CURRENT_KERNEL="$(opkg list-installed kernel)" && INSTALLER_VER_CURRENT="${CURRENT_KERNEL##* }"
# INSTALLER_VER_REMOTE=$(wget -qO- https://downloads.openwrt.org/snapshots/targets/${DISTRIB_TARGET}/packages/ \
#     | grep -Eo -m1 '>kernel_.*\.ipk' \
#     | sed -e 's/>kernel_//' -e 's/\.ipk//' -e "s|_${DISTRIB_TARGET/\//_}||" \
#     | head -n1)

# wget "https://downloads.openwrt.org/snapshots/targets/${DISTRIB_TARGET}/openwrt-${DISTRIB_TARGET/\//-}-generic-ext4-combined-efi.img.gz"
# gzip -d "openwrt-${DISTRIB_TARGET/\//-}-generic-ext4-combined-efi.img.gz"
# fdisk -lu "openwrt-${DISTRIB_TARGET/\//-}-generic-ext4-combined-efi.img"
# sudo mkdir -p /mnt/openwrt/boot

## mount 1st partition
# echo $((512*512)) # 262144
# sudo mount -o loop,offset=262144 "openwrt-${DISTRIB_TARGET/\//-}-generic-ext4-combined-efi.img" /mnt/openwrt/boot
# ls /mnt/openwrt/boot

## mount 2nd partition
# echo $((33792*512)) # 17301504
# sudo mount -o loop,offset=17301504 "openwrt-${DISTRIB_TARGET/\//-}-generic-ext4-combined-efi.img" /mnt/openwrt
# ls /mnt/openwrt

## replace `vmlinuz`
# mv -f /boot/vmlinuz /boot/vmlinuz.old
# scp "/mnt/openwrt/boot/boot/vmlinuz" openwrt:/boot

# sudo umount /mnt/openwrt
# sudo umount /mnt/openwrt-boot

## sysupgrade -v -p --test "openwrt-x86-64-generic-ext4-rootfs.img.gz"
## If extra partitions are added, you cannot use `-combined.img.gz` images anymore, 
## because writing this type of image will override the drive's partition table and delete any existing extra partition, 
## and also revert boot and rootfs partitions back to default size.
# cd ${WRT_WORKDIR}
# wget "https://downloads.openwrt.org/snapshots/targets/x86/64/openwrt-x86-64-generic-ext4-rootfs.img.gz" && \
#     sysupgrade -v -p "openwrt-x86-64-generic-ext4-rootfs.img.gz"

cd "${CURRENT_DIR}" || exit
