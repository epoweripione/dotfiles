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

[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
#     PROXY_ADDRESS="http://localhost:7890" && \
#         export {http,https,ftp,all}_proxy="${PROXY_ADDRESS}" && \
#         export {HTTP,HTTPS,FTP,ALL}_PROXY="${PROXY_ADDRESS}"
# fi

## https://www.openmediavault.org/
# http://<ip>
# admin:openmediavault

## Upload ssh public key
## echo '<public key>' >> ~/.ssh/authorized_keys
# ssh-copy-id -i ~/.ssh/id_ed25519.pub root@<ip>

apt install -y apt-transport-https apt-utils ca-certificates \
    lsb-release software-properties-common sudo curl wget

## https://omv-extras.org/
## wget -O - https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install | bash
# if [[ -z "${GITHUB_RAW_URL}" && "${THE_WORLD_BLOCKED}" == "true" ]]; then
#     GITHUB_RAW_URL="https://raw.fastgit.org"
# fi
# INSTALLER_DOWNLOAD_URL="${GITHUB_RAW_URL:-https://raw.githubusercontent.com}/OpenMediaVault-Plugin-Developers/packages/master/install"
# wget -O - "${INSTALLER_DOWNLOAD_URL}" | bash

# INSTALLER_DOWNLOAD_URL="https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install"
# curl -fsSL "${INSTALLER_DOWNLOAD_URL}" | bash

INSTALLER_DOWNLOAD_URL="https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install"
curl -fsSL -o "$HOME/omv_installer.sh" "${INSTALLER_DOWNLOAD_URL}" && \
    chmod +x "$HOME/omv_installer.sh" && \
    sudo "$HOME/omv_installer.sh" -n

[[ -f "$HOME/omv_installer.sh" ]] && rm -f "$HOME/omv_installer.sh"

## apt mirror
[[ -z "${MIRROR_PACKAGE_MANAGER_APT}" ]] && MIRROR_PACKAGE_MANAGER_APT="mirror.sjtu.edu.cn"
sed -i \
    -e "s|ftp.debian.org|${MIRROR_PACKAGE_MANAGER_APT}|g" \
    -e "s|deb.debian.org|${MIRROR_PACKAGE_MANAGER_APT}|g" \
    -e "s|security.debian.org/debian-security|${MIRROR_PACKAGE_MANAGER_APT}/debian-security|g" \
    -e "s|security.debian.org |${MIRROR_PACKAGE_MANAGER_APT}/debian-security |g" "/etc/apt/sources.list"

sed -i "s|http://${MIRROR_PACKAGE_MANAGER_APT}|https://${MIRROR_PACKAGE_MANAGER_APT}|g" "/etc/apt/sources.list"

sed -i "s|deb.debian.org|${MIRROR_PACKAGE_MANAGER_APT}|g" "/etc/apt/sources.list.d/openmediavault-kernel-backports.list"
sed -i "s|download.docker.com|${MIRROR_PACKAGE_MANAGER_APT}/docker-ce|g" "/etc/apt/sources.list.d/omvextras.list"

## omv apt mirror
# OMV_MIRROR="mirrors.tuna.tsinghua.edu.cn"
# omv-env set OMV_APT_SECURITY_REPOSITORY_URL "https://${OMV_MIRROR}/debian-security" && \
#     omv-env set OMV_APT_KERNEL_BACKPORTS_REPOSITORY_URL "https://${OMV_MIRROR}/debian" && \
#     omv-env set OMV_DOCKER_APT_REPOSITORY_URL "https://${OMV_MIRROR}/docker-ce/linux/debian" && \
#     omv-env set OMV_PROXMOX_APT_REPOSITORY_URL "https://${OMV_MIRROR}/proxmox/debian"

## omv-env set OMV_APT_REPOSITORY_URL "https://${OMV_MIRROR}/OpenMediaVault/public" && \
##     omv-env set OMV_APT_ALT_REPOSITORY_URL "https://${OMV_MIRROR}/OpenMediaVault/packages" && \
##     omv-env set OMV_EXTRAS_APT_REPOSITORY_URL "https://${OMV_MIRROR}/OpenMediaVault/openmediavault-plugin-developers"

## openmediavault defalut sources
## omv-env set OMV_APT_REPOSITORY_URL "https://packages.openmediavault.org/public" && \
##     omv-env set OMV_APT_ALT_REPOSITORY_URL "http://downloads.sourceforge.net/project/openmediavault/packages/" && \
##     omv-env set OMV_EXTRAS_APT_REPOSITORY_URL "https://openmediavault-plugin-developers.github.io/packages/debian"

# omv-salt stage run all

apt update && apt upgrade -y && apt dist-upgrade -y

# cockpit: http://<ip>:9090
apt install -y cockpit cockpit-*

# QEMU/KVM
apt install -y qemu-system libvirt-clients libvirt-daemon-system virt-manager bridge-utils

# sudo adduser $HOME libvirt && sudo adduser $HOME kvm
# echo export LIBVIRT_DEFAULT_URI='qemu:///system' | sudo tee -a /etc/environment
# source /etc/environment
