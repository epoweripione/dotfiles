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

# [OpenChamber - Desktop and web interface for OpenCode AI agent](https://github.com/openchamber/openchamber)
INSTALLER_APP_NAME="openchamber"
INSTALLER_GITHUB_REPO="openchamber/openchamber"
INSTALLER_BINARY_NAME="openchamber"

INSTALLER_NPM_PACKAGE="openchamber"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

# install nodejs & npm using fnm
fnm_Install_Nodejs

if [[ -x "$(command -v node)" && -x "$(command -v npm)" ]]; then
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
        curl -fsSL https://raw.githubusercontent.com/openchamber/openchamber/main/scripts/install.sh | bash
    fi
fi

: '
openchamber --ui-password be-creative-here

# Common operations:
openchamber status
openchamber connect-url --qr
openchamber tunnel start --provider cloudflare --mode quick --qr
openchamber startup enable
openchamber logs
openchamber stop
openchamber update

# OpenChamber binds to localhost by default
# Use `--lan` only on a trusted network and protect browser access with `--ui-password`
openchamber --ui-password addmin --host 192.168.x.x --port 5059

# Tunnel
openchamber tunnel start --provider cloudflare --mode quick
'
