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

# [Install .NET on Linux by using an install script](https://learn.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual)

# The script defaults to installing the latest long term support (LTS) SDK version
curl -fsSL -o "${WORKDIR}/dotnet-install.sh" https://dot.net/v1/dotnet-install.sh && \
    chmod +x "${WORKDIR}/dotnet-install.sh" && \
    "${WORKDIR}/dotnet-install.sh"

## To install the latest release, which might not be an (LTS) version, use the --version latest parameter
# "${WORKDIR}/dotnet-install.sh" --version latest

## To install .NET Runtime instead of the SDK, use the --runtime parameter
# "${WORKDIR}/dotnet-install.sh" --version latest --runtime aspnetcore

if [[ -d "$HOME/.dotnet" ]]; then
    export DOTNET_ROOT="$HOME/.dotnet"
    [[ ":$PATH:" != *":${DOTNET_ROOT}:"* ]] && export PATH=$PATH:${DOTNET_ROOT}:${DOTNET_ROOT}/tools
fi

# PowerShell
if [[ -x "$(command -v dotnet)" ]] && [[ ! -x "$(command -v pwsh)" ]]; then
    dotnet tool install --global PowerShell
fi
