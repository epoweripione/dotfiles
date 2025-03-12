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

# [Ollama - Get up and running with large language models](https://ollama.com/)
INSTALLER_GITHUB_REPO="ollama/ollama"
INSTALLER_BINARY_NAME="ollama"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_BINARY_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_BINARY_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

## test
# ollama run qwq # QwQ-32B

## [Where are models stored?](https://github.com/ollama/ollama/blob/main/docs/faq.md#where-are-models-stored)
# macOS: `~/.ollama/models`
# Linux: `/usr/share/ollama/.ollama/models`
# Windows: `C:\Users\%username%\.ollama\models`

## Environment variables
# OLLAMA_HOST="0.0.0.0:11434"
# OLLAMA_MODELS="/usr/share/ollama/.ollama/models"
