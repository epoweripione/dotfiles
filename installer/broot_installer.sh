#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

# Broot: A new way to see and navigate directory trees
# https://github.com/Canop/broot
APP_INSTALL_NAME="broot"
GITHUB_REPO_NAME="Canop/broot"

EXEC_INSTALL_PATH="/usr/local/bin"
EXEC_INSTALL_NAME="broot"

DOWNLOAD_FILENAME="${WORKDIR}/${EXEC_INSTALL_NAME}"

DOWNLOAD_URL=""
REMOTE_FILENAME=""

IS_INSTALL="yes"
IS_UPDATE="no"

INSTALL_FROM_SOURCE="no"
EXEC_FULL_NAME=""

CURRENT_VERSION="0.0.0"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    EXEC_FULL_NAME=$(which ${EXEC_INSTALL_NAME})
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | grep 'tag_name' | cut -d\" -f4 | cut -d'v' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

# Install Latest Version
if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    if [[ -n "${EXEC_FULL_NAME}" ]] && [[ "${EXEC_FULL_NAME}" != *"${EXEC_INSTALL_PATH}"* ]]; then
        [[ -x "$(command -v cargo)" || -x "$(command -v brew)" ]] && INSTALL_FROM_SOURCE="yes"
    fi
fi

if [[ "${INSTALL_FROM_SOURCE}" == "yes" ]]; then
    # From source on crates.io
    [[ -x "$(command -v cargo)" ]] && cargo install "${APP_INSTALL_NAME}"

    # Install via Homebrew
    [[ ! -x "$(command -v cargo)" && -x "$(command -v brew)" ]] && brew install "${APP_INSTALL_NAME}"
elif [[ "${INSTALL_FROM_SOURCE}" == "no" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_ARCH}" in
                arm)
                    DOWNLOAD_URL="https://dystroy.org/broot/download/armv7-unknown-linux-gnueabihf/broot"
                    ;;
                arm64)
                    DOWNLOAD_URL="https://dystroy.org/broot/download/aarch64-linux-android/broot"
                    ;;
                *)
                    DOWNLOAD_URL="https://dystroy.org/broot/download/x86_64-unknown-linux-musl/broot"
                    ;;
            esac
            ;;
        windows)
            DOWNLOAD_URL="https://dystroy.org/broot/download/x86_64-pc-windows-gnu/broot.exe"
            ;;
    esac
fi

if [[ "${IS_INSTALL}" == "yes" && -n "${DOWNLOAD_URL}" ]]; then
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -eq 0 ]]; then
        sudo cp -f "${DOWNLOAD_FILENAME}" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
            sudo chmod +x "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}"
    fi

    # vscode font
    FONT_URL="https://raw.githubusercontent.com/Canop/broot/master/resources/icons/vscode/vscode.ttf"
    FONT_FILE="${WORKDIR}/vscode.ttf"
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${FONT_FILE}" "${FONT_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -eq 0 ]]; then
        mkdir -p "$HOME/.local/share/fonts" && \
            cp -f "${FONT_FILE}" "$HOME/.local/share/fonts"
    fi
fi

# Shell completion
if [[ "${IS_INSTALL}" == "yes" && -x "$(command -v broot)" ]]; then
    [[ ! -s "$HOME/.config/broot/launcher/bash/br" ]] && broot --install

    # if [[ -s "$HOME/.config/broot/conf.hjson" ]]; then
    #     sed -i "s/# icon_theme: vscode/icon_theme: vscode/" "$HOME/.config/broot/conf.hjson"
    # fi
fi

cd "${CURRENT_DIR}" || exit