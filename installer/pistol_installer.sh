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

# pistol: General purpose file previewer designed for Ranger, Lf to make scope.sh redundant
# https://github.com/doronbehar/pistol
INSTALLER_APP_NAME="pistol"
INSTALLER_GITHUB_REPO="doronbehar/pistol"

INSTALLER_INSTALL_NAME="pistol"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" && -x "$(command -v go)" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_FILE="$(which ${INSTALLER_INSTALL_NAME}).version"
    [[ -s "${INSTALLER_VER_FILE}" ]] && INSTALLER_VER_CURRENT=$(head -n1 "${INSTALLER_VER_FILE}")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

[[ ! -x "$(command -v go)" ]] && INSTALLER_IS_INSTALL="no"

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"

    if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

        if [[ -x "$(command -v pacman)" ]]; then
            # Pre-requisite packages
            PackagesList=(
                libmagic
                libmagic-dev
                file-devel
            )
            for TargetPackage in "${PackagesList[@]}"; do
                if checkPackageNeedInstall "${TargetPackage}"; then
                    colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
                    sudo pacman --noconfirm -S "${TargetPackage}"
                fi
            done
        fi

        go install "github.com/doronbehar/pistol/cmd/pistol@latest"

        if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
            INSTALLER_VER_FILE="$(which ${INSTALLER_INSTALL_NAME}).version"
            echo "${INSTALLER_VER_REMOTE}" | sudo tee "${INSTALLER_VER_FILE}" >/dev/null || true
        fi
    fi
fi


cd "${CURRENT_DIR}" || exit