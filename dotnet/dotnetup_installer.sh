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

# [Get started with dotnetup](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnetup/getting-started)

if [[ -x "$(command -v dotnetup)" ]]; then
    INSTALLER_IS_UPDATE="yes"
    dotnetup self update
else
    curl -fsSL https://aka.ms/dotnetup/get-dotnetup.sh | bash
fi

if [[ -d "$HOME/.dotnetup" ]]; then
    export DOTNETUP_ROOT="$HOME/.dotnetup"
    [[ ":$PATH:" != *":${DOTNETUP_ROOT}:"* ]] && export PATH=$PATH:${DOTNETUP_ROOT}
fi

if [[ -x "$(command -v dotnetup)" ]]; then
    if [[ "${INSTALLER_IS_UPDATE}" == "yes" ]]; then
        dotnetup sdk update --all
    else
        dotnetup init
        dotnetup list
    fi
fi

# PowerShell
if [[ -x "$(command -v dotnet)" ]] && [[ ! -x "$(command -v pwsh)" ]]; then
    dotnet tool install --global PowerShell
fi

# dotnetup sdk install
# dotnetup sdk install preview
# dotnetup sdk install daily

# dotnetup runtime install
# dotnetup runtime install daily
# dotnetup runtime install aspnetcore@10.0
