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

# [pgenv - PostgreSQL binary manager](https://github.com/theory/pgenv)
INSTALLER_APP_NAME="pgenv"
INSTALLER_GITHUB_REPO="theory/pgenv"

if [[ -d "$HOME/.pgenv" ]]; then
    INSTALLER_IS_UPDATE="yes"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Updating ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
    Git_Clone_Update_Branch "${INSTALLER_GITHUB_REPO}" "$HOME/.pgenv"
fi

if [[ -d "$HOME/.pgenv" ]]; then
    [[ ":$PATH:" != *":$HOME/.pgenv/bin:"* ]] && export PATH=$PATH:$HOME/.pgenv/bin:$HOME/.pgenv/pgsql/bin
fi
