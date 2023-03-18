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

# hyperfine: A command-line benchmarking tool
# https://github.com/sharkdp/hyperfine
INSTALLER_APP_NAME="hyperfine"
INSTALLER_GITHUB_REPO="sharkdp/hyperfine"

INSTALLER_INSTALL_NAME="hyperfine"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_ARCHIVE_EXEC_DIR="hyperfine-*"

INSTALLER_ZSH_COMP_FILE="_hyperfine"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    INSTALLER_EXEC_FULLNAME=$(readlink -f "$(which ${INSTALLER_INSTALL_NAME})")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    INSTALLER_INSTALL_METHOD="custom"

    if checkPackageExists "${INSTALLER_APP_NAME}"; then
        INSTALLER_INSTALL_METHOD="pacman"
    else
        if [[ -n "${INSTALLER_EXEC_FULLNAME}" ]] && [[ "${INSTALLER_EXEC_FULLNAME}" != *"${INSTALLER_INSTALL_PATH}"* ]]; then
            [[ -x "$(command -v cargo)" || -x "$(command -v brew)" ]] && INSTALLER_INSTALL_METHOD="build"
        fi
    fi
fi

# pacman
if [[ "${INSTALLER_INSTALL_METHOD}" == "pacman" ]]; then
    if checkPackageNeedInstall "${INSTALLER_APP_NAME}"; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        [[ -x "$(command -v pacman)" ]] && sudo pacman --noconfirm -S "${INSTALLER_APP_NAME}"
    fi
fi

# app installer
if [[ "${INSTALLER_INSTALL_METHOD}" == "custom" ]]; then
    if ! App_Installer_Install; then
        if [[ -z "${INSTALLER_EXEC_FULLNAME}" && "${INSTALLER_IS_INSTALL}" == "nomatch" ]] &&
            [[ -x "$(command -v cargo)" || -x "$(command -v brew)" ]]; then
            # first time install: maybe no match install file to download, use build instead
            INSTALLER_INSTALL_METHOD="build"
        else
            colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
        fi
    fi
fi

# homebrew or build from source
if [[ "${INSTALLER_INSTALL_METHOD}" == "build" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    # Install via Homebrew
    [[ -x "$(command -v brew)" ]] && brew install "${INSTALLER_APP_NAME}"

    # From source on crates.io
    [[ ! -x "$(command -v brew)" && -x "$(command -v cargo)" ]] && cargo install "${INSTALLER_APP_NAME}"
fi


cd "${CURRENT_DIR}" || exit