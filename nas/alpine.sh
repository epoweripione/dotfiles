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

# https://wiki.alpinelinux.org/wiki/Alpine_setup_scripts
ifconfig eth0 up
udhcpc eth0

setup-apkrepos

# OS_VERSION_ID=$(head -n1 /etc/alpine-release | cut -d'.' -f1-2)
## echo "https://dl-cdn.alpinelinux.org/alpine/v${OS_VERSION_ID}/main" | tee -a "/etc/apk/repositories"
## echo "https://dl-cdn.alpinelinux.org/alpine/v${OS_VERSION_ID}/community" | tee -a "/etc/apk/repositories"
# echo "https://mirror.sjtu.edu.cn/alpine/v${OS_VERSION_ID}/main" | tee -a "/etc/apk/repositories"
# echo "https://mirror.sjtu.edu.cn/alpine/v${OS_VERSION_ID}/community" | tee -a "/etc/apk/repositories"

apk add e2fsprogs‑extra parted

# ls /dev/sd*
# fdisk -l
# parted -l
# parted /dev/sda print

setup-alpine
