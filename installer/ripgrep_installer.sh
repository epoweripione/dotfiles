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

# [ripgrep: recursively searches directories for a regex pattern while respecting your gitignore](https://github.com/BurntSushi/ripgrep)
INSTALLER_APP_NAME="ripgrep"
INSTALLER_GITHUB_REPO="BurntSushi/ripgrep"

INSTALLER_ARCHIVE_EXT="tar.gz"

INSTALLER_INSTALL_NAME="rg"

INSTALLER_ZSH_COMP_FILE="_rg"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    INSTALLER_EXEC_FULLNAME=$(readlink -f "$(which ${INSTALLER_INSTALL_NAME})")
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

# Install Latest Version
if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    INSTALLER_INSTALL_METHOD="custom"

    if [[ -n "${INSTALLER_EXEC_FULLNAME}" ]] && [[ "${INSTALLER_EXEC_FULLNAME}" != *"${INSTALLER_INSTALL_PATH}"* ]]; then
        INSTALLER_INSTALL_METHOD="mise"
    fi
fi

if [[ "${INSTALLER_INSTALL_METHOD}" == "mise" ]]; then
    [[ ! -x "$(command -v rg)" && "$(command -v mise)" ]] && mise use --global ripgrep@latest
    [[ ! -x "$(command -v rg)" && "$(command -v asdf)" ]] && asdf_App_Install ripgrep
elif [[ "${INSTALLER_INSTALL_METHOD}" == "custom" ]]; then
    if ! App_Installer_Install; then
        colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
    fi
fi
