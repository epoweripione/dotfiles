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

INSTALLER_INSTALL_NAME="croc"
INSTALLER_ZSH_COMP_FILE="zsh_autocomplete"
INSTALLER_ZSH_COMP_INSTALL="_croc"

INSTALLER_ARCHIVE_EXT="tar.gz"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if App_Installer_Install; then
    [[ -f "/etc/zsh/zsh_autocomplete_croc" ]] && sudo rm -f "/etc/zsh/zsh_autocomplete_croc"
else
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi

# colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

# INSTALLER_CHECK_URL="https://api.github.com/repos/schollz/croc/releases/latest"
# App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"

# INSTALLER_FILE_NAME="croc"

# if [[ -x "$(command -v croc)" ]]; then
#     INSTALLER_VER_CURRENT=$(croc -v | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
#     if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
#         INSTALLER_FILE_NAME=""
#     fi
# fi

# if [[ -n "${INSTALLER_VER_REMOTE}" && -n "${INSTALLER_FILE_NAME}" ]]; then
#     colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
#     curl https://getcroc.schollz.com | bash
# fi
