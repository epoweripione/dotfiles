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

# [Broot: A new way to see and navigate directory trees](https://github.com/Canop/broot)
INSTALLER_APP_NAME="broot"
INSTALLER_GITHUB_REPO="Canop/broot"

INSTALLER_INSTALL_PATH="/usr/local/bin"
INSTALLER_INSTALL_NAME="broot"

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
        [[ -x "$(command -v cargo)" || -x "$(command -v brew)" ]] && INSTALLER_INSTALL_METHOD="build"
    fi
fi

if [[ "${INSTALLER_INSTALL_METHOD}" == "build" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    # Install via Homebrew
    [[ -x "$(command -v brew)" ]] && brew install "${INSTALLER_APP_NAME}"

    # From source on crates.io
    [[ ! -x "$(command -v brew)" && -x "$(command -v cargo)" ]] && cargo install "${INSTALLER_APP_NAME}"
elif [[ "${INSTALLER_INSTALL_METHOD}" == "custom" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_ARCH}" in
                arm)
                    INSTALLER_ARCHIVE_EXEC_DIR="armv7-unknown-linux-gnueabihf"
                    ;;
                arm64)
                    INSTALLER_ARCHIVE_EXEC_DIR="aarch64-linux-android"
                    ;;
                *)
                    INSTALLER_ARCHIVE_EXEC_DIR="x86_64-unknown-linux-musl"
                    ;;
            esac
            ;;
        windows)
            INSTALLER_ARCHIVE_EXEC_DIR="x86_64-pc-windows-gnu"
            ;;
    esac

    INSTALLER_DOWNLOAD_URL="https://github.com/Canop/broot/releases/download/v${INSTALLER_VER_REMOTE}/broot_${INSTALLER_VER_REMOTE}.zip"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" && -n "${INSTALLER_ARCHIVE_EXEC_DIR}" ]]; then
    if App_Installer_Install; then
        # vscode font
        FONT_FILE=$(find "${WORKDIR}" -type f -name "vscode.ttf")
        if [[ -s "${FONT_FILE}" ]]; then
            mkdir -p "$HOME/.local/share/fonts" && \
                mv -f "${FONT_FILE}" "$HOME/.local/share/fonts"
        fi
    else
        colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
    fi
fi

# Shell completion
if [[ "${INSTALLER_IS_INSTALL}" == "yes" && -x "$(command -v broot)" ]]; then
    [[ ! -f "$HOME/.config/broot/launcher/bash/br" ]] && broot --install

    # if [[ -s "$HOME/.config/broot/conf.hjson" ]]; then
    #     sed -i "s/# icon_theme: vscode/icon_theme: vscode/" "$HOME/.config/broot/conf.hjson"
    # fi
fi

cd "${CURRENT_DIR}" || exit