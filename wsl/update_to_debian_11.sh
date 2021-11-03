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

# Check GRUB
colorEcho "${BLUE}Getting ${FUCHSIA}GRUB menu entry${BLUE}..."
[[ -x "$(command -v grub2-editenv)" ]] && grub2-editenv list
[[ -f "/boot/grub/grub.cfg" ]] && awk -F\' '/menuentry / {print $2}' "/boot/grub/grub.cfg"
[[ -f "/boot/grub2/grub.cfg" ]] && awk -F\' '/menuentry / {print $2}' "/boot/grub2/grub.cfg"

# Update ALL existing installed packages
colorEcho "${BLUE}Update ALL existing installed packages..."
sudo apt update && sudo apt upgrade -y && sudo apt full-upgrade -y && sudo apt --purge autoremove -y

# Reconfigure APT’s source-list files
colorEcho "${BLUE}Reconfigure APT’s source-list files..."
sudo sed -i 's|debian-security/ buster/updates|debian-security bullseye-security|' "/etc/apt/sources.list" && \
    sudo sed -i 's|debian-security buster/updates|debian-security bullseye-security|' "/etc/apt/sources.list" && \
    sudo sed -i 's|buster|bullseye|' "/etc/apt/sources.list"

[[ -s "/etc/apt/sources.list.d/docker.list" ]] && sudo sed -i 's|buster|bullseye|' "/etc/apt/sources.list.d/docker.list"

# Updating the package list && Minimal system upgrade && Upgrading Debian 10 to Debian 11
colorEcho "${BLUE}Updating the package list, Minimal system upgrade and Upgrading Debian 10 to Debian 11..."
sudo apt update && sudo apt upgrade --without-new-pkgs -y && sudo apt full-upgrade -y

# Check GRUB
colorEcho "${BLUE}Getting ${FUCHSIA}GRUB menu entry${BLUE}..."
[[ -x "$(command -v grub2-editenv)" ]] && grub2-editenv list
[[ -f "/boot/grub/grub.cfg" ]] && awk -F\' '/menuentry / {print $2}' "/boot/grub/grub.cfg"
[[ -f "/boot/grub/grub2.cfg" ]] && awk -F\' '/menuentry / {print $2}' "/boot/grub2/grub.cfg"

## Reboot
# sudo systemctl reboot

## Restart WSL in PowerShell
# Stop-Service -Name "LxssManager" && Start-Service -Name "LxssManager"

## verification
# uname -a && cat /etc/*-release
# sudo journalctl

## Clean up outdated packages
# sudo apt --purge autoremove -y

colorEcho "${BLUE}Upgrade done."
colorEcho "${BLUE}Please carefully review the update logs above and confirm everything is ok."
colorEcho "${BLUE}Then you can reboot your system!"
