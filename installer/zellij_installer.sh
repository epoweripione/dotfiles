#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

# zellij - A terminal workspace with batteries included
# https://github.com/zellij-org/zellij
APP_INSTALL_NAME="zellij"
GITHUB_REPO_NAME="zellij-org/zellij"

EXEC_INSTALL_NAME="zellij"

ARCHIVE_EXT="tar.gz"
ARCHIVE_EXEC_NAME="zellij"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if App_Installer_Install; then
    # Autostart on shell creation
    # bash
    if ! grep -q "zellij setup" "$HOME/.bashrc" 2>/dev/null; then
        echo -e '\n# Autostart a new zellij shell\nexport ZELLIJ_AUTO_ATTACH=true' >> "$HOME/.bashrc"
        echo 'eval "$(zellij setup --generate-auto-start bash)"' >> "$HOME/.bashrc"
    fi

    # zsh
    if ! grep -q "zellij setup" "$HOME/.zshrc" 2>/dev/null; then
        echo -e '\n# Autostart a new zellij shell\nexport ZELLIJ_AUTO_ATTACH=true' >> "$HOME/.zshrc"
        echo 'eval "$(zellij setup --generate-auto-start zsh)"' >> "$HOME/.zshrc"
    fi
else
    colorEcho "${RED}  Install ${FUCHSIA}${APP_INSTALL_NAME}${RED} failed!"
fi

cd "${CURRENT_DIR}" || exit
