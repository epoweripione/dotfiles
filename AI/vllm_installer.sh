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

# [vLLM - A high-throughput and memory-efficient inference and serving engine for LLMs](https://github.com/vllm-project/vllm)
INSTALLER_APP_NAME="vLLM"
INSTALLER_GITHUB_REPO="vllm-project/vllm"
INSTALLER_BINARY_NAME="vllm"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    colorEcho "${FUCHSIA}${INSTALLER_APP_NAME}${BLUE} is already installed."
fi

if [[ ! -x "$(command -v uv)" ]]; then
    [[ -f "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/uv_installer.sh" ]] && \
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/uv_installer.sh"
fi

# [How to Serve LLMs Locally with vLLM and uv](https://pydevtools.com/handbook/how-to/how-to-use-vllm-with-uv/)
if [[ ! -x "$(command -v ${INSTALLER_BINARY_NAME})" ]] && [[ -x "$(command -v uv)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE} to ${ORANGE}$HOME/vllm${BLUE}..."
    uvCreateVenv "$HOME/vllm"
    uv pip install vllm --torch-backend=auto
fi

cd "${CURRENT_DIR}" || exit 1
