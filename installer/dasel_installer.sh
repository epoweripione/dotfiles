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

# dasel: Select, put and delete data from JSON, TOML, YAML, XML and CSV files with a single tool.
# Supports conversion between formats and can be used as a Go package.
# https://github.com/TomWright/dasel
[[ ! -x "$(command -v dasel)" && -x "$(command -v rtx)" ]] && rtx global dasel@latest
[[ ! -x "$(command -v dasel)" && "$(command -v asdf)" ]] && asdf_App_Install dasel
