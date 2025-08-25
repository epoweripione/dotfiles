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
UPGRADE_REPO_VERSION="9.0-30"

# current OS release info
[[ -z "${OS_RELEASE_ID}" ]] && get_os_release_info
[[ -z "${OS_INFO_ARCH}" ]] && get_arch

if [[ "${OS_RELEASE_ID}" != "centos" || "${OS_RELEASE_VER}" != "8" || "${OS_INFO_CPU_ARCH}" != "x86_64" ]]; then
    colorEcho "${RED}This script is only for CentOS 8 x86_64 systems!"
    exit 1
fi

MIRROR_CENTOS_STREAM=${MIRROR_CENTOS_STREAM:-"http://mirror.stream.centos.org"}

## /etc/yum.repos.d/
# dnf repolist

## /etc/dnf/modules.d/
# dnf module list

colorEcho "${BLUE}Updating installed packages..."
sudo dnf -y upgrade

# colorEcho "${BLUE}Removing ${FUCHSIA}rpmconf yum-utils epel-release${BLUE}..."
# sudo dnf -y remove rpmconf yum-utils epel-release

colorEcho "${BLUE}Installing ${FUCHSIA}rpmconf yum-utils epel-release${BLUE}..."
sudo dnf -y install rpmconf yum-utils epel-release

colorEcho "${BLUE}Running rpmconf (answer \"n\" to all)..."
sudo rpmconf -a

colorEcho "${BLUE}Cleaning packages..."
sudo package-cleanup --leaves
sudo package-cleanup --orphans

colorEcho "${BLUE}Installing new repos..."
sudo dnf -y install \
    "${MIRROR_CENTOS_STREAM}/${UPGRADE_RELEASE_VER}-stream/BaseOS/${OS_INFO_CPU_ARCH}/os/Packages/centos-stream-repos-${UPGRADE_REPO_VERSION}.el${UPGRADE_RELEASE_VER}.noarch.rpm" \
    "${MIRROR_CENTOS_STREAM}/${UPGRADE_RELEASE_VER}-stream/BaseOS/${OS_INFO_CPU_ARCH}/os/Packages/centos-stream-release-${UPGRADE_REPO_VERSION}.el${UPGRADE_RELEASE_VER}.noarch.rpm" \
    "${MIRROR_CENTOS_STREAM}/${UPGRADE_RELEASE_VER}-stream/BaseOS/${OS_INFO_CPU_ARCH}/os/Packages/centos-gpg-keys-${UPGRADE_REPO_VERSION}.el${UPGRADE_RELEASE_VER}.noarch.rpm"

colorEcho "${BLUE}Installing epel repos..."
curl -o "${WORKDIR}/epel-release-latest-${UPGRADE_RELEASE_VER}.noarch.rpm" "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${UPGRADE_RELEASE_VER}.noarch.rpm"
curl -o "${WORKDIR}/epel-next-release-latest-${UPGRADE_RELEASE_VER}.noarch.rpm" "https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-${UPGRADE_RELEASE_VER}.noarch.rpm"
sudo rpm -Uvh "${WORKDIR}"/*.rpm

## fix: Modular dependency problems
## remove the modules by deleting their metadata files from `/etc/dnf/modules.d/`
## dnf module list
# find "/etc/dnf/modules.d/" -type f ! -name "javapackages-runtime.module" -exec /bin/rm -f {} \;
colorEcho "${BLUE}Updating modules..."
sudo dnf module disable python36 python39 perl perl-IO-Socket-SSL perl-libwww-perl

# fix: Couldn't open file /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
if [[ ! -s "/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8" ]]; then
    # sudo curl -o "/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8" "https://archive.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8"

    # grep 'RPM-GPG-KEY-EPEL-8' /etc/yum.repos.d/*.repo
    sudo mv "/etc/yum.repos.d/epel.repo" "/etc/yum.repos.d/epel.repo.8"
    sudo mv "/etc/yum.repos.d/epel-testing.repo" "/etc/yum.repos.d/epel-testing.repo.8"
fi

# disable subscription-manager
sudo sed -i 's/enabled=1/enabled=0/' "/etc/yum/pluginconf.d/subscription-manager.conf"

sudo dnf -y --releasever=${UPGRADE_RELEASE_VER} --allowerasing --setopt=deltarpm=false swap python39-setuptools python3-setuptools

colorEcho "${BLUE}Updating packages..."
# fix: Found bdb_ro Packages database while attempting sqlite backend: using bdb_ro backend
sudo rm -f /var/lib/rpm/__db*
sudo rpm --rebuilddb
sudo dnf -y update --allowerasing
sudo dnf -y clean all

# dnf list installed kernel
# rpm -qa kernel
sudo rpm -e "$(rpm -q kernel)"

colorEcho "${BLUE}Switch to Centos Stream ${UPGRADE_RELEASE_VER}..."
sudo dnf -y --releasever=${UPGRADE_RELEASE_VER} --allowerasing --setopt=deltarpm=false distro-sync

colorEcho "${BLUE}Installing Centos Stream ${UPGRADE_RELEASE_VER} kernel..."
sudo dnf -y install kernel kernel-core shim
# ls -la /boot/loader/entries
sudo grub2-mkconfig -o "/boot/grub2/grub.cfg"
sudo dnf -y clean all

## Reboot
# sudo reboot

## Run follow command after reboot
# sudo rm -f /var/lib/rpm/__db*; sudo rpm --rebuilddb; sudo dnf -y update; sudo dnf -y groupupdate "Core" "Minimal Install"

colorEcho "${BLUE}Upgrade done."
colorEcho "${BLUE}Please carefully review the update logs above and confirm everything is ok."
colorEcho "${BLUE}Then you can reboot your system!"

colorEcho "${BLUE}Run follow command after reboot:"
colorEcho '${FUCHSIA}sudo rm -f /var/lib/rpm/__db*; sudo rpm --rebuilddb; sudo dnf -y update; sudo dnf -y groupupdate "Core" "Minimal Install"'


## Use Rescue Mode to fix missing kernel & GRUB
# mkdir -p /mnt/vm1
# mount /dev/vda1 /mnt/vm1

# for i in /dev /dev/pts /proc /run /sys; do mount -o bind $i /mnt/vm1${i}; done
# chroot /mnt/vm1 /bin/bash

# dnf -y install kernel kernel-core shim
# grub2-mkconfig -o /boot/grub2/grub.cfg
# exit

# for i in /dev /dev/pts /proc /run /sys; do umount /mnt/vm1${i}; done
# reboot
