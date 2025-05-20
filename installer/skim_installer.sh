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

# skim - Fuzzy Finder in rust
# https://github.com/lotabout/skim
INSTALLER_APP_NAME="skim"
INSTALLER_GITHUB_REPO="lotabout/skim"

INSTALLER_INSTALL_NAME="sk"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_ARCHIVE_EXEC_NAME="sk"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    INSTALLER_EXEC_FULLNAME=$(readlink -f "$(which ${INSTALLER_INSTALL_NAME})")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

# if ! App_Installer_Install; then
#     colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
# fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    if checkPackageExists "${INSTALLER_APP_NAME}"; then
        INSTALLER_INSTALL_METHOD="pacman"
    else
        [[ -x "$(command -v cargo)" || -x "$(command -v brew)" ]] && INSTALLER_INSTALL_METHOD="build"
    fi
fi

if [[ "${INSTALLER_INSTALL_METHOD}" == "build" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    # Install via Homebrew
    if [[ -x "$(command -v brew)" ]]; then
        if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
            brew upgrade "sk"
        else
            brew install "sk"
        fi
    fi

    # From source on crates.io
    [[ ! -x "$(command -v brew)" && -x "$(command -v cargo)" ]] && cargo install "${INSTALLER_APP_NAME}"
elif [[ "${INSTALLER_INSTALL_METHOD}" == "pacman" ]]; then
    if checkPackageNeedInstall "${INSTALLER_APP_NAME}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        [[ -x "$(command -v pacman)" ]] && sudo pacman --noconfirm -S "${INSTALLER_APP_NAME}"
    fi
fi

cd "${CURRENT_DIR}" || exit
