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

# [Perceptual JPEG encoder](https://github.com/google/guetzli)
INSTALLER_APP_NAME="guetzli"
INSTALLER_GITHUB_REPO="google/guetzli"

colorEcho "${BLUE}Installing ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
# Pre-requisite packages
PackagesList=(
    "libpng"
    "libpng-dev"
    "libpng-devel"
)
InstallSystemPackages "" "${PackagesList[@]}"

Git_Clone_Update_Branch "${INSTALLER_GITHUB_REPO}" "$HOME/${INSTALLER_APP_NAME}"
if [[ -d "$HOME/${INSTALLER_APP_NAME}" ]]; then
    cd "$HOME/${INSTALLER_APP_NAME}" && \
        make && \
        sudo cp "$HOME/${INSTALLER_APP_NAME}/bin/Release/guetzli" "${INSTALLER_INSTALL_PATH}" && \
        sudo chmod +x "${INSTALLER_INSTALL_PATH}/${INSTALLER_APP_NAME}"
fi

cd "${CURRENT_DIR}" || exit
