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

# # [version-manager(vmr) – A general version manager for 60+ SDKs with TUI inspired by lazygit](https://github.com/gvcgo/version-manager)
INSTALLER_GITHUB_REPO="gvcgo/version-manager"
INSTALLER_BINARY_NAME="vmr"

INSTALLER_MATCH_PATTERN="vmr*"

INSTALLER_ARCHIVE_EXT="zip"

INSTALLER_VER_FILE="${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}.version"

installPrebuiltBinary "${INSTALLER_BINARY_NAME}#${INSTALLER_GITHUB_REPO}#${INSTALLER_ARCHIVE_EXT}#${INSTALLER_MATCH_PATTERN}"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    if ! grep -q "vmr completion zsh" "$HOME/.zshrc" 2>/dev/null; then
        vmr install-self

        # shell completion
        echo -e '\n# vmr completion\nsource <(vmr completion zsh)' >> "$HOME/.zshrc"
    fi
fi
