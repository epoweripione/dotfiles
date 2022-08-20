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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# pistol: General purpose file previewer designed for Ranger, Lf to make scope.sh redundant
# https://github.com/doronbehar/pistol
APP_INSTALL_NAME="pistol"
GITHUB_REPO_NAME="doronbehar/pistol"

EXEC_INSTALL_NAME="pistol"

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" && -x "$(command -v go)" ]]; then
    IS_UPDATE="yes"
    VERSION_FILENAME="$(which ${EXEC_INSTALL_NAME}).version"
    [[ -s "${VERSION_FILENAME}" ]] && CURRENT_VERSION=$(head -n1 "${VERSION_FILENAME}")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

[[ ! -x "$(command -v go)" ]] && IS_INSTALL="no"

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."
    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)

    if version_gt "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."

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

        noproxy_cmd go install "github.com/doronbehar/pistol/cmd/pistol@latest"

        if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
            VERSION_FILENAME="$(which ${EXEC_INSTALL_NAME}).version"
            echo "${REMOTE_VERSION}" | sudo tee "${VERSION_FILENAME}" >/dev/null || true
        fi
    fi
fi


cd "${CURRENT_DIR}" || exit