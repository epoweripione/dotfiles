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

# [huggingface_hub cli](https://huggingface.co/docs/huggingface_hub/guides/cli)
INSTALLER_BINARY_NAME="hf"

if [[ ! -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}${INSTALLER_BINARY_NAME}${BLUE}..."
    # pip_Package_Install "huggingface_hub[cli]"

    curl -LsSf https://hf.co/cli/install.sh | bash
fi
