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

# [llama.cpp - LLM inference in C/C++](https://github.com/ggml-org/llama.cpp)
INSTALLER_APP_NAME="llama.cpp"
INSTALLER_GITHUB_REPO="ggml-org/llama.cpp"
INSTALLER_BINARY_NAME="llama"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_BINARY_NAME} --version 2>/dev/null | awk -F- '{print $1}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    curl -LsSf https://llama.app/install.sh | sh
fi

: '
if [[ ! -x "$(command -v micromamba)" ]] && [[ ! -x "$(command -v mamba)" ]] && [[ ! -x "$(command -v conda)" ]] && [[ ! -x "$(command -v pixi)" ]]; then
    [[ -f "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/micromamba_installer.sh" ]] && \
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/micromamba_installer.sh"
fi

if [[ ! -x "$(command -v micromamba)" ]] && [[ ! -x "$(command -v mamba)" ]] && [[ ! -x "$(command -v conda)" ]] && [[ ! -x "$(command -v pixi)" ]]; then
    colorEcho "${RED}No supported package manager found!"
    exit 1
fi

if [[ -x "$(command -v micromamba)" ]]; then
    micromamba install -c conda-forge llama.cpp
elif [[ -x "$(command -v mamba)" ]]; then
    mamba install -c conda-forge llama.cpp
elif [[ -x "$(command -v conda)" ]]; then
    conda install -c conda-forge llama.cpp
elif [[ -x "$(command -v pixi)" ]]; then
    pixi global install llama.cpp
fi
'
