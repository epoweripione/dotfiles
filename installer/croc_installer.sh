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

APP_INSTALL_NAME="croc"
GITHUB_REPO_NAME="schollz/croc"

EXEC_INSTALL_NAME="croc"
ZSH_COMPLETION_FILE="zsh_autocomplete"
ZSH_COMPLETION_INSTALL_NAME="_croc"

ARCHIVE_EXT="tar.gz"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if App_Installer_Install; then
    [[ -f "/etc/zsh/zsh_autocomplete_croc" ]] && sudo rm -f "/etc/zsh/zsh_autocomplete_croc"
else
    colorEcho "${RED}  Install ${FUCHSIA}${APP_INSTALL_NAME}${RED} failed!"
fi

# colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

# CHECK_URL="https://api.github.com/repos/schollz/croc/releases/latest"
# App_Installer_Get_Remote_Version "${CHECK_URL}"

# REMOTE_FILENAME="croc"

# if [[ -x "$(command -v croc)" ]]; then
#     CURRENT_VERSION=$(croc -v | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
#     if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
#         REMOTE_FILENAME=""
#     fi
# fi

# if [[ -n "$REMOTE_VERSION" && -n "$REMOTE_FILENAME" ]]; then
#     colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
#     curl https://getcroc.schollz.com | bash
# fi
