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

## /etc/yum.repos.d/
# dnf repolist

## /etc/dnf/modules.d/
# dnf module list

colorEcho "${BLUE}Updating installed packages..."
sudo dnf -y upgrade --refresh

colorEcho "${BLUE}Adding ${FUCHSIA}Rocky Linux 9 Repositories${BLUE}..."
# [Packages](https://download.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/r/)
REPO_URL="https://download.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/r"
RELEASE_PKG="rocky-release-9.5-1.3.el9.noarch.rpm"
REPOS_PKG="rocky-repos-9.5-1.3.el9.noarch.rpm"
GPG_KEYS_PKG="rocky-gpg-keys-9.5-1.3.el9.noarch.rpm"

sudo dnf -y install $REPO_URL/$RELEASE_PKG $REPO_URL/$REPOS_PKG $REPO_URL/$GPG_KEYS_PKG

colorEcho "${BLUE}Removing unnecessary packages..."
sudo dnf -y remove rpmconf yum-utils epel-release
sudo rm -rf /usr/share/redhat-logos

colorEcho "${BLUE}Installing Rocky Linux 9 packages..."
sudo dnf -y --releasever=9 --allowerasing --setopt=deltarpm=false distro-sync

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
