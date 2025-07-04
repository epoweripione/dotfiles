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

App_Installer_Reset

# [Unhide - a forensic tool to find hidden processes and TCP/UDP ports by rootkits / LKMs or by another hiding technique](https://github.com/YJesus/Unhide)
INSTALLER_APP_NAME="Unhide"
INSTALLER_GITHUB_REPO="YJesus/Unhide"

INSTALLER_INSTALL_NAME="unhide"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(sudo ${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
    Git_Clone_Update_Branch "${INSTALLER_GITHUB_REPO}" "${WORKDIR}/${INSTALLER_APP_NAME}"
fi

if [[ -f "${WORKDIR}/${INSTALLER_APP_NAME}/build_all.sh" ]]; then
    # Pre-requisite packages
    PackagesList=(
        "build-essential"
        "gcc"
        "glibc-devel"
        "glibc-static-devel"
        "iproute2"
        "lsof"
        "make"
        "net-tools"
        "netstat"
        "procps"
        "psmisc"
        "sockstat"
    )
    InstallSystemPackages "" "${PackagesList[@]}"

    cd "${WORKDIR}/${INSTALLER_APP_NAME}" && \
        ./build_all.sh && \
        sudo cp -f unhide-linux "${INSTALLER_INSTALL_PATH}/unhide" && \
        sudo cp -f unhide_rb "${INSTALLER_INSTALL_PATH}/unhide_rb" && \
        sudo cp -f unhide-tcp "${INSTALLER_INSTALL_PATH}/unhide-tcp" && \
        sudo cp -f unhide-posix "${INSTALLER_INSTALL_PATH}/unhide-posix" && \
        sudo chmod +x "${INSTALLER_INSTALL_PATH}"/unhide*
fi

cd "${CURRENT_DIR}" || exit