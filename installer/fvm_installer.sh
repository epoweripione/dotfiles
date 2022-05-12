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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

# Flutter Version Management: A simple CLI to manage Flutter SDK versions
# https://github.com/fluttertools/fvm
APP_INSTALL_NAME="fvm"

if [[ ! -x "$(command -v brew)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/homebrew_installer.sh" ]] && \
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/homebrew_installer.sh"
fi

if [[ -x "$(command -v brew)" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."
    brew tap leoafarias/fvm
    brew install fvm
fi
