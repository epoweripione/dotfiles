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

# [Coder - Self-Hosted Cloud Development Environments and AI Agents](https://github.com/coder/coder)
INSTALLER_APP_NAME="coder"
INSTALLER_GITHUB_REPO="coder/coder"
INSTALLER_BINARY_NAME="coder"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
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
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    curl -fsSL https://coder.com/install.sh | sh
fi

## Start the server and open http://localhost:3000
## to create your initial user, create a Docker template, and provision your first workspace:
# coder server

## For a production deployment, add a PostgreSQL database (version 13 or later) and an external access URL,
## and see our validated architectures for sizing and infrastructure guidance:
# coder server --postgres-url <url> --access-url <url>
