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
UPGRADE_RELEASE_VER="10"
UPGRADE_REPO_VERSION="10.0-10"

# current OS release info
[[ -z "${OS_RELEASE_ID}" ]] && get_os_release_info
[[ -z "${OS_INFO_ARCH}" ]] && get_arch

if [[ "${OS_RELEASE_ID}" != "centos" || "${OS_RELEASE_VER}" != "9" || "${OS_INFO_CPU_ARCH}" != "x86_64" ]]; then
    colorEcho "${RED}This script is only for CentOS 9 x86_64 systems!"
    exit 1
fi

# Remove packages left from centos 8
while read -r pkg; do
    sudo rpm -e --nodeps "${pkg}"
done < <(rpm -qa | grep el8)

# Do a upgrade
sudo dnf -y upgrade

# Clean up
sudo dnf -y clean all

# [ELevate NG](https://wiki.almalinux.org/elevate/ELevate-NG-testing-guide.html)
sudo curl -o /etc/yum.repos.d/elevate-ng.repo "https://repo.almalinux.org/elevate/testing/elevate-ng-el$(rpm -E %rhel).repo" && \
    sudo rpm --import https://repo.almalinux.org/elevate/RPM-GPG-KEY-ELevate

# Upgrade to CentOS Stream 10
sudo yum install -y leapp-upgrade leapp-data-centos

## Upgrade to AlmaLinux 10
# sudo yum install -y leapp-upgrade leapp-data-almalinux

[[ ! -x "$(command -v leapp)" ]] && {
    colorEcho "${RED}leapp command not found, please check the above command output for errors."
    exit 1
}

# Start a preupgrade check
sudo leapp preupgrade

## Fix `error: Verifying a signature using certificate 99DB70FAE1D7CE227FB6488205B555B38483C65D`
# sudo rpm -e gpg-pubkey-8483c65d-5ccc5b19 2>/dev/null
# sudo rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256

## Start an upgrade
# sudo leapp upgrade
colorEcho "${BLUE}Before continuing, review the full ${FUCHSIA}leapp${BLUE} report for details about discovered problems and possible remediation instructions."
colorEcho "${RED}Please carefully review the ${FUCHSIA}leapp${BLUE} report above."
colorEcho "${BLUE}If everything is OK, you can upgrade your system by running command ${FUCHSIA}sudo leapp upgrade${BLUE} ."

# sudo reboot

## After reboot, login to the system and check how the upgrade went.
## Verify that the current OS is the one you need.
## Check logs and packages left from the previous OS version, consider removing them or upgrade them manually.
# cat /etc/redhat-release
# cat /etc/os-release
# rpm -qa | grep el9
# sudo cat /var/log/leapp/leapp-report.txt
# sudo cat /var/log/leapp/leapp-upgrade.log
