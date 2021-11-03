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

USBDISK=${1:-"sdb1"}
[[ ! -d "/mnt/${USBDISK}" && -b "/dev/${USBDISK}" ]] && mkdir "/mnt/${USBDISK}" && mount -o rw,noatime "/dev/${USBDISK}" "/mnt/${USBDISK}"

[[ -d "/mnt/${USBDISK}" ]] && WRT_WORKDIR="/mnt/${USBDISK}" || WRT_WORKDIR="/tmp"
[[ -d "${WRT_WORKDIR}" ]] && OPKG_EXTRAS="${WRT_WORKDIR}/opkg-extras.sh" || OPKG_EXTRAS="$PWD/opkg-extras.sh"

# Restore previously saved OpenWrt configuration from local PC
if [[ ! -s "/restore.ok" ]]; then
    BACKUP_FILE=$(find "${WRT_WORKDIR}" -type f -name "backup-*.tar.gz" | sort -r | head -n1)
    [[ -n "${BACKUP_FILE}" ]] && sysupgrade -r "${BACKUP_FILE}"
    echo 'ok' > "/restore.ok"
    reboot
fi

opkg update

## Install missing devices driver
# opkg install kmod-e1000

# Saving/restoring user-installed packages
opkg install libustream-mbedtls

if [[ ! -s "${OPKG_EXTRAS}" ]]; then
    uclient-fetch -O "${OPKG_EXTRAS}" "https://openwrt.org/_export/code/docs/guide-user/advanced/opkg_extras?codeblock=0"
fi

[[ -s "${OPKG_EXTRAS}" ]] && . "${OPKG_EXTRAS}"

# Restore Opkg profile
opkg update
opkg restore

# Fix: Read-only file system
mount -o remount rw /

# Upgrade packages
opkg list-upgradable 2>/dev/null | awk '{print $1}' | grep -Ev 'netifd|base-files|kmod|Multiple' | while read -r line; do opkg upgrade "$line"; done

cd "${CURRENT_DIR}" || exit
