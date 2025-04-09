#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

[[ -z "${MY_SHELL_SCRIPTS}" ]] && MY_SHELL_SCRIPTS="$HOME/.dotfiles"

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

# https://snapcraft.io/
if [[ ! -x "$(command -v snap)" ]]; then
    [[ -z "${OS_PACKAGE_MANAGER}" ]] && get_os_package_manager

    if [[ "${OS_PACKAGE_MANAGER}" == "dnf" ]]; then
        if checkPackageNeedInstall "epel-release"; then
            sudo dnf install epel-release && sudo dnf upgrade
        fi
    fi

    if [[ -x "$(command -v pacman)" ]]; then
        # Pre-requisite packages
        PackagesList=(
            snapd
        )
        InstallSystemPackages "" "${PackagesList[@]}"
    fi
fi

if [[ -x "$(command -v snap)" ]]; then
    colorEcho "${BLUE}Setting ${FUCHSIA}snap${BLUE}..."
    systemctl is-enabled snapd.service >/dev/null 2>&1 || sudo systemctl enable --now snapd.service
    systemctl is-enabled snapd.socket >/dev/null 2>&1 || sudo systemctl enable --now snapd.socket
    systemctl is-enabled snapd.apparmor.service >/dev/null 2>&1 || sudo systemctl enable --now snapd.apparmor.service

    # enable classic snap support
    [[ ! -d "/snap" && -d "/var/lib/snapd/snap" ]] && sudo ln -s /var/lib/snapd/snap /snap

    # Fix: error: too early for operation, device not yet seeded or device model not acknowledged
    sleep 3

    # sudo snap install core

    [[ ":$PATH:" != *":/snap/bin:"* ]] && export PATH=$PATH:/snap/bin

    ## test
    # sudo snap install hello-world
    # hello-world
fi

## System options
## https://snapcraft.io/docs/system-options
# snap get system proxy.http
# snap get system proxy.https
# sudo snap set system proxy.http="http://127.0.0.1:7890"
# sudo snap set system proxy.https="http://127.0.0.1:7890"
# sudo snap unset system proxy.http
# sudo snap unset system proxy.https
