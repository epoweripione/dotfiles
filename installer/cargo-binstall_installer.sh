#!/usr/bin/env bash

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

# [Cargo B(inary)Install - Binary installation for rust projects](https://github.com/cargo-bins/cargo-binstall)
INSTALLER_GITHUB_REPO="cargo-bins/cargo-binstall"
INSTALLER_BINARY_NAME="cargo-binstall"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_BINARY_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_BINARY_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    if [[ "${INSTALLER_IS_UPDATE}" == "yes" ]]; then
        cargo binstall --no-confirm cargo-binstall
    else
        curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
    fi

    if [[ -x "$(command -v cargo-binstall)" ]]; then
        # [cargo-update: checking and applying updates to installed executables](https://github.com/nabijaczleweli/cargo-update)
        cargo binstall --no-confirm cargo-update
        # [cargo-run-bin: Build, cache, and run CLI tools scoped in Cargo.toml rather than installing globally](https://github.com/dustinblackman/cargo-run-bin)
        cargo binstall --no-confirm cargo-run-bin
    fi
fi
