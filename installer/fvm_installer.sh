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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# [Easy, powerful and flexible tool to manage multiple Flutter SDK versions](https://fvm.app/)
INSTALLER_APP_NAME="fvm"
INSTALLER_GITHUB_REPO="leoafarias/fvm"

if [[ ! "$(command -v fvm)" ]]; then
    App_Installer_Get_Remote_Version
    App_Installer_Get_Installed_Version "${INSTALLER_APP_NAME}"
    if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        curl -fsSL https://fvm.app/install.sh | bash
    fi
fi

if [[ ! "$(command -v fvm)" ]]; then
    if [[ ! -x "$(command -v brew)" ]]; then
        [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/homebrew_installer.sh" ]] && \
            source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/homebrew_installer.sh"
    fi

    if [[ -x "$(command -v brew)" ]]; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
        brew tap leoafarias/fvm
        brew install fvm
    fi
fi

## Basic Commands
## https://fvm.app/docs/guides/basic_commands
## Sets Flutter SDK Version you would like to use in a project
## If version does not exist it will ask if you want to install
# fvm use {version}

## Installs Flutter SDK Version. Gives you the ability to install Flutter releases or channels
# fvm install - # Installs version found in project config
# fvm install {version} - # Installs specific version

## Removes Flutter SDK Version. Will impact any projects that depend on that version of the SDK
# fvm remove {version}

## Lists installed Flutter SDK Versions. Will also print the cache directory used by FVM
# fvm list

## View all Flutter SDK releases available for install
# fvm releases

## Shows information about environment, and project configuration
# fvm doctor
