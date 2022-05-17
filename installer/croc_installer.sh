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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

# croc - Easily and securely send things from one computer to another
# https://github.com/schollz/croc

## Usage:
## Self-host relay (docker)
# docker run -d -p 9009-9013:9009-9013 -e CROC_PASS='YOURPASSWORD' schollz/croc
## Send file(s)-or-folder 
# croc --pass YOURPASSWORD --relay "myreal.example.com:9009" send [file(s)-or-folder]
## Receive the file(s)-or-folder on another computer
# croc --pass YOURPASSWORD --relay "myreal.example.com:9009" [code-phrase]

APP_INSTALL_NAME="croc"

colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

CHECK_URL="https://api.github.com/repos/schollz/croc/releases/latest"
REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)

REMOTE_FILENAME="croc"

if [[ -x "$(command -v croc)" ]]; then
    CURRENT_VERSION=$(croc -v | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        REMOTE_FILENAME=""
    fi
fi

if [[ -n "$REMOTE_VERSION" && -n "$REMOTE_FILENAME" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    curl https://getcroc.schollz.com | bash
fi