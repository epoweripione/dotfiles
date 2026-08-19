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

# [Unsloth is the first desktop app to run and train models](https://github.com/unslothai/unsloth)
# [Unsloth Desktop](https://unsloth.ai/)
INSTALLER_APP_NAME="unsloth"
INSTALLER_GITHUB_REPO="unslothai/unsloth"
INSTALLER_BINARY_NAME="unsloth"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

# install nodejs & npm using fnm
fnm_Install_Nodejs

if [[ -x "$(command -v python)" && -x "$(command -v node)" ]]; then
    if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
        colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

        App_Installer_Get_Pip_Package_Remote_Version "${INSTALLER_APP_NAME}"
        if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
            INSTALLER_IS_INSTALL="no"
        fi
    fi

    if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        curl -fsSL https://unsloth.ai/install.sh | sh
    fi
fi

## launch Unsloth Studio
# unsloth studio -p 8888

## for LAN / cloud access; exposes the raw port only, not a public URL
# unsloth studio -p 8888 -H 0.0.0.0

## for a public Cloudflare HTTPS link
# unsloth studio -p 8888 -H 0.0.0.0 --cloudflare

## for a public Cloudflare HTTPS link & to keep the raw port private, anyone with the API key can run code
# unsloth studio -p 8888 -H 0.0.0.0 --cloudflare --secure

## WSL: Launch Unsloth from Windows:
# wsl -d "Debian" -- bash -lc 'unsloth studio'
