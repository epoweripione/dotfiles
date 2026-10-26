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

# [Octop: A smarter, self-hosted AI assistant — multi-user, multi-agent](https://github.com/TencentCloud/Octop)
INSTALLER_APP_NAME="octop"
INSTALLER_GITHUB_REPO="TencentCloud/Octop"
INSTALLER_BINARY_NAME="octop"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ -x "$(command -v pip)" ]]; then
    if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
        colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

        App_Installer_Get_Pip_Package_Remote_Version "${INSTALLER_APP_NAME}"
        if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
            INSTALLER_IS_INSTALL="no"
        fi
    fi

    if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        curl -fsSL https://finnie-1258344699.cos.ap-guangzhou.myqcloud.com/octop/install.sh | bash
    fi
fi

## Usage:
##Initialize
# octop init

## Run in the foreground (API + Web console)
# octop run

## Custom host / port
# octop run --host 0.0.0.0 --port 8088

## Register as a system service (systemd / launchd / Windows service)
# octop service start

## open `http://127.0.0.1:8088`

## Cleanup
# octop clean

## Playwright reinstall:
# $HOME/.octop/venv/bin/python -m playwright install chromium
