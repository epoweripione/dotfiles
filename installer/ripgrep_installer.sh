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

# ripgrep: recursively searches directories for a regex pattern while respecting your gitignore
# https://github.com/BurntSushi/ripgrep
[[ ! -x "$(command -v rg)" && "$(command -v mise)" ]] && mise use --global ripgrep@latest
[[ ! -x "$(command -v rg)" && "$(command -v asdf)" ]] && asdf_App_Install ripgrep
