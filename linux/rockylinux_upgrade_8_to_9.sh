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

# Upgrade release info
UPGRADE_RELEASE_VER="9"
UPGRADE_REPO_VERSION="9.6-1.3"

# current OS release info
[[ -z "${OS_RELEASE_ID}" ]] && get_os_release_info
[[ -z "${OS_INFO_ARCH}" ]] && get_arch

if [[ "${OS_RELEASE_ID}" != "rocky" || "${OS_RELEASE_VER}" != "9" || "${OS_INFO_CPU_ARCH}" != "x86_64" ]]; then
    colorEcho "${RED}This script is only for Rocky Linux 9 x86_64 systems!"
    exit 1
fi

## /etc/yum.repos.d/
# dnf repolist

## /etc/dnf/modules.d/
# dnf module list

colorEcho "${BLUE}Updating installed packages..."
sudo dnf -y upgrade --refresh

colorEcho "${BLUE}Adding ${FUCHSIA}Rocky Linux ${UPGRADE_RELEASE_VER} Repositories${BLUE}..."
# [Packages](https://download.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/r/)
REPO_URL="https://download.rockylinux.org/pub/rocky/${UPGRADE_RELEASE_VER}/BaseOS/${OS_INFO_CPU_ARCH}/os/Packages/r"
RELEASE_PKG="rocky-release-${UPGRADE_REPO_VERSION}.el${UPGRADE_RELEASE_VER}.noarch.rpm"
REPOS_PKG="rocky-repos-${UPGRADE_REPO_VERSION}.el${UPGRADE_RELEASE_VER}.noarch.rpm"
GPG_KEYS_PKG="rocky-gpg-keys-${UPGRADE_REPO_VERSION}.el${UPGRADE_RELEASE_VER}.noarch.rpm"

sudo dnf -y install "$REPO_URL/$RELEASE_PKG" "$REPO_URL/$REPOS_PKG" "$REPO_URL/$GPG_KEYS_PKG"

colorEcho "${BLUE}Removing unnecessary packages..."
sudo dnf -y remove rpmconf yum-utils epel-release
sudo rm -rf /usr/share/redhat-logos

colorEcho "${BLUE}Installing Rocky Linux ${UPGRADE_RELEASE_VER} packages..."
sudo dnf -y --releasever=${UPGRADE_RELEASE_VER} --allowerasing --setopt=deltarpm=false distro-sync

## Fix: conflict packages
# sudo dnf -y remove valgrind iptables-ebtables

## Fix: GPG key failed
## Find the GPG key IDs
# rpm -qa gpg*
## Remove the existing one
# sudo rpm -e --allmatches gpg-pubkey-[REPOKEYID]
## Install the right GPG key by running:
# sudo rpm --import https://dl.rockylinux.org/pub/rocky/RPM-GPG-KEY-Rocky-9

colorEcho "${BLUE}Rebuilding RPM Database..."
sudo rm -f /var/lib/rpm/__db*
sudo rpm --rebuilddb
sudo dnf -y update
sudo dnf -y clean all

# List installed kernel
rpm -qa kernel

## Reboot
# sudo reboot

colorEcho "${BLUE}Upgrade done."
colorEcho "${BLUE}Please carefully review the update logs above and confirm everything is ok."
colorEcho "${BLUE}Then you can reboot your system!"
