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

# [Micromamba](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html)
"${SHELL}" <(curl -L micro.mamba.pm/install.sh)

if [[ "$(command -v micromamba)" ]]; then
    if ! grep -q 'mamba initialize' "$HOME/.bashrc" >/dev/null 2>&1; then
        micromamba shell init -s bash
    fi

    if ! grep -q 'mamba initialize' "$HOME/.zshrc" >/dev/null 2>&1; then
        micromamba shell init -s zsh
    fi

    # conda mirror
    setMirrorConda

    micromamba update -y --all

    micromamba config append channels conda-forge
    micromamba config set auto_activate_base false
fi
