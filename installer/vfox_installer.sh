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

# [A cross-platform and extendable version manager](https://github.com/version-fox/vfox)
INSTALLER_GITHUB_REPO="version-fox/vfox"
INSTALLER_BINARY_NAME="vfox"

INSTALLER_ARCHIVE_EXT="tar.gz"

# INSTALLER_ADDON_FILES=(
#     "_vfox#https://raw.githubusercontent.com/version-fox/vfox/main/completions/zsh_autocomplete#${INSTALLER_ZSH_FUNCTION_PATH}/_vfox"
# )
INSTALLER_ZSH_COMP_FILE="zsh_autocomplete"
INSTALLER_ZSH_COMP_INSTALL="_vfox"

if installPrebuiltBinary "${INSTALLER_BINARY_NAME}#${INSTALLER_GITHUB_REPO}#${INSTALLER_ARCHIVE_EXT}"; then
    # Hook vfox to Shell
    # bash
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q "vfox activate" "$HOME/.bashrc"; then
            echo -e '\n# [VersionFox](https://github.com/version-fox/vfox)' >> "$HOME/.bashrc"
            echo 'eval "$(vfox activate bash)"' >> "$HOME/.bashrc"
        fi
    fi

    # zsh
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "vfox activate" "$HOME/.zshrc"; then
            echo -e '\n# [VersionFox](https://github.com/version-fox/vfox)' >> "$HOME/.zshrc"
            echo 'eval "$(vfox activate zsh)"' >> "$HOME/.zshrc"
        fi
    fi
fi
