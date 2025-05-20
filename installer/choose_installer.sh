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

# choose: A human-friendly and fast alternative to cut and (sometimes) awk
# https://github.com/theryangeary/choose
INSTALLER_APP_NAME="choose"
INSTALLER_GITHUB_REPO="theryangeary/choose"

INSTALLER_INSTALL_NAME="choose"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

[[ ! -x "$(command -v cargo)" && ! -x "$(command -v brew)" ]] && INSTALLER_IS_INSTALL="no"

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
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    if [[ -x "$(command -v "${INSTALLER_INSTALL_NAME}")" ]]; then
        binary_full=$(readlink -f "$(which "${INSTALLER_INSTALL_NAME}")")
        case "${binary_full}" in
            *cargo*)
                [[ -x "$(command -v cargo)" ]] && cargo install "${INSTALLER_APP_NAME}"
                ;;
            *brew*)
                [[ -x "$(command -v brew)" ]] && brew upgrade "choose-rust"
                ;;
        esac
    else
        # From source on crates.io
        [[ -x "$(command -v cargo)" ]] && cargo install "${INSTALLER_APP_NAME}"

        # Install via Homebrew
        [[ ! -x "$(command -v cargo)" && -x "$(command -v brew)" ]] && brew install "choose-rust"
    fi
fi


cd "${CURRENT_DIR}" || exit