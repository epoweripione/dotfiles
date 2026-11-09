#!/usr/bin/env bash

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

# croc - Easily and securely send things from one computer to another
# https://github.com/schollz/croc

## Usage:
## Self-host relay (docker)
# docker run -d -p 9009-9013:9009-9013 -e CROC_PASS='YOURPASSWORD' schollz/croc
## Send file(s)-or-folder 
# croc --pass YOURPASSWORD --relay "myreal.example.com:9009" send [file(s)-or-folder]
## Receive the file(s)-or-folder on another computer
# croc --pass YOURPASSWORD --relay "myreal.example.com:9009" [code-phrase]

INSTALLER_APP_NAME="croc"
INSTALLER_GITHUB_REPO="schollz/croc"

INSTALLER_BINARY_NAME="croc"

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
    if [[ "${INSTALLER_IS_UPDATE}" == "yes" ]]; then
        croc update --yes 2>/dev/null
    else
        curl -fsSL https://getcroc.com | bash
    fi
fi
