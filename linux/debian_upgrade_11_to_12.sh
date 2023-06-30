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

# [How to upgrade Debian 11 to Debian 12 bookworm using CLI](https://www.cyberciti.biz/faq/update-upgrade-debian-11-to-debian-12-bookworm/)

# Check GRUB
colorEcho "${BLUE}Getting ${FUCHSIA}GRUB menu entry${BLUE}..."
[[ -x "$(command -v grub2-editenv)" ]] && grub2-editenv list
[[ -f "/boot/grub/grub.cfg" ]] && awk -F\' '/menuentry / {print $2}' "/boot/grub/grub.cfg"
[[ -f "/boot/grub2/grub.cfg" ]] && awk -F\' '/menuentry / {print $2}' "/boot/grub2/grub.cfg"

## Find non-Debian packages
# sudo apt list '?narrow(?installed, ?not(?origin(Debian)))'

## Find package in hold status
# sudo apt-mark showhold | more

# Update ALL existing installed packages
colorEcho "${BLUE}Update ALL existing installed packages..."
sudo apt update && sudo apt upgrade -y && sudo apt full-upgrade -y && sudo apt --purge autoremove -y

# Reconfigure APT’s source-list files
colorEcho "${BLUE}Reconfigure APT source-list files..."
[[ ! -s "/etc/apt/sources.list-11-bullseye.bak" ]] && \
    sudo cp "/etc/apt/sources.list" "/etc/apt/sources.list-11-bullseye.bak"

sudo sed -i -e 's|debian-security/ bullseye/updates|debian-security bookworm-security|' \
    -e 's|debian-security bullseye/updates|debian-security bookworm-security|' \
    -e 's|bullseye|bookworm|' "/etc/apt/sources.list"

# Non-Free-Firmware Repositories
APT_MIRROR=$(grep -E '^deb\s+' "/etc/apt/sources.list" | head -n1 | awk '{print $2}' | cut -d'/' -f1-3)
[[ -z "${APT_MIRROR}" ]] && APT_MIRROR="http://deb.debian.org"

if ! grep -q "non-free-firmware" "/etc/apt/sources.list" 2>/dev/null; then
    sudo sed -i -e 's/ non-free/ non-free non-free-firmware/g' "/etc/apt/sources.list"
fi

if ! grep -q "non-free-firmware" "/etc/apt/sources.list" 2>/dev/null; then
    sudo sed -i -e 's/ contrib/ contrib non-free non-free-firmware/g' "/etc/apt/sources.list"
fi

if ! grep -q "non-free-firmware" "/etc/apt/sources.list" 2>/dev/null; then
    sudo sed -i -e 's/ main/ main contrib non-free non-free-firmware/g' "/etc/apt/sources.list"
fi

if ! grep -q "non-free-firmware" "/etc/apt/sources.list" 2>/dev/null; then
    sudo tee -a "/etc/apt/sources.list" >/dev/null <<-EOF

# Non-Free-Firmware
deb ${APT_MIRROR}/debian bookworm main contrib non-free non-free-firmware
deb-src ${APT_MIRROR}/debian bookworm main contrib non-free non-free-firmware

deb ${APT_MIRROR}/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src ${APT_MIRROR}/debian-security bookworm-security main contrib non-free non-free-firmware

deb ${APT_MIRROR}/debian bookworm-updates main contrib non-free non-free-firmware
deb-src ${APT_MIRROR}/debian bookworm-updates main contrib non-free non-free-firmware
EOF
fi

if [[ -s "/etc/apt/sources.list.d/docker.list" ]]; then
    [[ ! -s "/etc/apt/sources.list.d/docker.list-11-bullseye.bak" ]] && \
        sudo cp "/etc/apt/sources.list.d/docker.list" "/etc/apt/sources.list.d/docker.list-11-bullseye.bak"

    sudo sed -i 's|bullseye|bookworm|' "/etc/apt/sources.list.d/docker.list"

    DOCKER_MIRROR=$(sed -e 's|https://||' -e 's|http://||' <<<"${APT_MIRROR}")
    sudo sed -i "s|download.docker.com|${DOCKER_MIRROR}/docker-ce|" "/etc/apt/sources.list.d/docker.list"
fi

# Updating the package list && Minimal system upgrade && Upgrading Debian 11 to Debian 12
colorEcho "${BLUE}Updating the package list, Minimal system upgrade and Upgrading Debian 11 to Debian 12..."
sudo apt update && sudo apt upgrade --without-new-pkgs -y && sudo apt full-upgrade -y

# Verify SSHD config file
colorEcho "${BLUE}Verify ${FUCHSIA}SSHD config file${BLUE}..."
sudo sshd -t

# Check GRUB
colorEcho "${BLUE}Getting ${FUCHSIA}GRUB menu entry${BLUE}..."
[[ -x "$(command -v grub2-editenv)" ]] && grub2-editenv list
[[ -f "/boot/grub/grub.cfg" ]] && awk -F\' '/menuentry / {print $2}' "/boot/grub/grub.cfg"
[[ -f "/boot/grub/grub2.cfg" ]] && awk -F\' '/menuentry / {print $2}' "/boot/grub2/grub.cfg"

## Reboot
# sudo systemctl reboot

## Restart WSL in PowerShell
# Stop-Service -Name "LxssManager" && Start-Service -Name "LxssManager" # Windows 10
# Stop-Service -Name "WslService" && Start-Service -Name "WslService" # Windows 11

## verification
# uname -a && lsb_release -a && cat /etc/*-release
# sudo journalctl

## Clean up outdated packages
# sudo apt --purge autoremove -y

colorEcho "${BLUE}Upgrade done."
colorEcho "${BLUE}Please carefully review the update logs above and confirm everything is ok."
colorEcho "${BLUE}Then you can reboot your system!"
