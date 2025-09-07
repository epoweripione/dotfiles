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

# Upgrade release info
UPGRADE_RELEASE_VER="12"
UPGRADE_RELEASE_CODENAME="bookworm"

# current OS release info
[[ -z "${OS_RELEASE_ID}" ]] && get_os_release_info

if [[ "${OS_RELEASE_ID}" != "debian" || "${OS_RELEASE_VER}" != "11" || "${OS_RELEASE_CODENAME}" != "bullseye" ]]; then
    colorEcho "${RED}This script is only for Debian 11 (bullseye) systems!"
    exit 1
fi

# mirror site
if [[ -z "${MIRROR_PACKAGE_MANAGER_APT}" && -f "/etc/apt/sources.list" ]]; then
    MIRROR_PACKAGE_MANAGER_APT=$(grep '^deb' /etc/apt/sources.list 2>/dev/null | head -n1 | awk '{print $2}' | awk -F "/" '{print $3}')
fi

if [[ -z "${MIRROR_PACKAGE_MANAGER_APT}" && -f "/etc/apt/sources.list.d/debian.sources" ]]; then
    MIRROR_PACKAGE_MANAGER_APT=$(grep '^URIs:' /etc/apt/sources.list.d/debian.sources 2>/dev/null | head -n1 | awk '{print $2}' | awk -F "/" '{print $3}')
fi

MIRROR_PACKAGE_MANAGER_APT="${MIRROR_PACKAGE_MANAGER_APT:-"deb.debian.org"}"

## installed packages
# dpkg -l
# dpkg --get-selections '*'
# apt list --installed

## obsolete packages
# apt list '?narrow(?installed, ?not(?origin(Debian)))'

## package status
# dpkg --audit

# Check GRUB
colorEcho "${BLUE}Getting ${FUCHSIA}GRUB menu entry${BLUE}..."
[[ -x "$(command -v grub2-editenv)" ]] && grub2-editenv list
[[ -f "/boot/grub/grub.cfg" ]] && awk -F\' '/menuentry / {print $2}' "/boot/grub/grub.cfg"
[[ -f "/boot/grub2/grub.cfg" ]] && awk -F\' '/menuentry / {print $2}' "/boot/grub2/grub.cfg"

# Update ALL existing installed packages
colorEcho "${BLUE}Update ALL existing installed packages..."
sudo apt update && sudo apt upgrade -y && sudo apt full-upgrade -y && sudo apt autoclean -y && sudo apt --purge autoremove -y

# Check System Status: Verify system integrity before upgrade
sudo apt --fix-broken install
sudo dpkg --configure -a

# Hold some packages
# [avoid an issue where mdadm is updated before systemd and shows an error that it cannot find systemd](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1111649)
HOLD_PKGS=()

for PKG in "${HOLD_PKGS[@]}"; do
    if dpkg --get-selections '*' | grep -q "^${PKG}"; then
        colorEcho "${BLUE}Hold ${FUCHSIA}${PKG}${BLUE} package..."
        sudo apt-mark hold "${PKG}" 2>/dev/null
    fi
done

# Reconfigure APT’s source-list files using DEB822 format
colorEcho "${BLUE}Reconfigure APT source-list files..."
if [[ -f "/etc/apt/sources.list" ]]; then
    sudo cp /etc/apt/sources.list "/etc/apt/sources.list-${OS_RELEASE_VER}-${OS_RELEASE_CODENAME}.bak" && \
        sudo rm -f /etc/apt/sources.list
fi

if [[ -f "/etc/apt/sources.list.d/debian.sources" ]]; then
    sudo cp /etc/apt/sources.list.d/debian.sources "/etc/apt/sources.list.d/debian.sources-${OS_RELEASE_VER}-${OS_RELEASE_CODENAME}.bak" && \
        sudo rm -f /etc/apt/sources.list.d/debian.sources
fi

# Official repos - Using DEB822 format
sudo tee "/etc/apt/sources.list.d/debian.sources" >/dev/null <<-EOF
Types: deb
URIs: http://${MIRROR_PACKAGE_MANAGER_APT}/debian
Suites: ${UPGRADE_RELEASE_CODENAME} ${UPGRADE_RELEASE_CODENAME}-updates ${UPGRADE_RELEASE_CODENAME}-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Types: deb-src
# URIs: http://${MIRROR_PACKAGE_MANAGER_APT}/debian
# Suites: ${UPGRADE_RELEASE_CODENAME} ${UPGRADE_RELEASE_CODENAME}-updates ${UPGRADE_RELEASE_CODENAME}-backports
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://${MIRROR_PACKAGE_MANAGER_APT}/debian-security
Suites: ${UPGRADE_RELEASE_CODENAME}-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Types: deb-src
# URIs: http://${MIRROR_PACKAGE_MANAGER_APT}/debian-security
# Suites: ${UPGRADE_RELEASE_CODENAME}-security
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# 3rd-party repos
sudo find /etc/apt/sources.list.d -type f -exec sed -i "s/${OS_RELEASE_CODENAME}/${UPGRADE_RELEASE_CODENAME}/g" {} \;

# Updating the package list && Minimal system upgrade
colorEcho "${BLUE}Updating the package list, Minimal system upgrade and Upgrading Debian ${OS_RELEASE_VER} to Debian ${UPGRADE_RELEASE_VER}..."
sudo apt update && sudo apt upgrade --without-new-pkgs -y && sudo apt full-upgrade -y

# Update unhold packages and clean up
colorEcho "${BLUE}Update unhold packages and clean up..."
for PKG in "${HOLD_PKGS[@]}"; do
    if dpkg --get-selections '*' | grep -q "^${PKG}"; then
        colorEcho "${BLUE}Unhold ${FUCHSIA}${PKG}${BLUE} package..."
        sudo apt-mark unhold "${PKG}" 2>/dev/null
    fi
done

# apt list --upgradable
sudo apt update && sudo apt upgrade -y && sudo apt full-upgrade -y && sudo apt autoclean -y && sudo apt --purge autoremove -y

# Verify System Version
colorEcho "${BLUE}Verify ${FUCHSIA}System Version${BLUE}..."
lsb_release -a
cat /etc/*-release

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
# Stop-Service -Name "LxssManager" && Start-Service -Name "LxssManager" # WSL1
# Stop-Service -Name "WslService" && Start-Service -Name "WslService" # WSL2

## verification
# uname -a && lsb_release -a && cat /etc/*-release
# sudo journalctl

## Clean up outdated packages
# sudo apt --purge autoremove -y

colorEcho "${BLUE}Upgrade done."
colorEcho "${BLUE}Please carefully review the update logs above and confirm everything is ok."
colorEcho "${BLUE}Then you can reboot your system!"
