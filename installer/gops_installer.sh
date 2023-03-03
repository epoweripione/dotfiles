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

# [gops](https://github.com/google/gops)
APP_INSTALL_NAME="gops"
GITHUB_REPO_NAME="google/gops"

EXEC_INSTALL_NAME="gops"

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
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
    App_Installer_Get_Remote_Version "${CHECK_URL}"

    if version_gt "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."

        go install "github.com/google/gops@latest"

        if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
            VERSION_FILENAME="$(which ${EXEC_INSTALL_NAME}).version"
            echo "${REMOTE_VERSION}" | sudo tee "${VERSION_FILENAME}" >/dev/null || true
        fi
    fi
fi


cd "${CURRENT_DIR}" || exit