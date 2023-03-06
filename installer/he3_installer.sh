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

# [He3](https://he3.app/)
APP_INSTALL_NAME="He3"

EXEC_INSTALL_PATH="$HOME/Applications"

DOWNLOAD_FILENAME="He3.AppImage"
VERSION_FILENAME="${DOWNLOAD_FILENAME}.version"

if [[ -f "${EXEC_INSTALL_PATH}/${DOWNLOAD_FILENAME}" ]]; then
    IS_UPDATE="yes"
    [[ -s "${EXEC_INSTALL_PATH}/${VERSION_FILENAME}" ]] && CURRENT_VERSION=$(head -n1 "${EXEC_INSTALL_PATH}/${VERSION_FILENAME}")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

# REMOTE_VERSION="1.2.9"
if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://raw.githubusercontent.com/he3-app/homebrew-he3/main/Casks/he3.rb"
    App_Installer_Get_Remote_Version "${CHECK_URL}" "version.*"
    version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}" && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_VDIS}" ]] && get_sysArch

    REMOTE_FILENAME=""
    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_VDIS}" in
                64)
                    REMOTE_FILENAME="He3_linux_x86_64_${REMOTE_VERSION}.AppImage"
                    ;;
                arm64)
                    REMOTE_FILENAME="He3_linux_arm64_${REMOTE_VERSION}.AppImage"
                    ;;
            esac
            ;;
        darwin)
            case "${OS_INFO_VDIS}" in
                64)
                    REMOTE_FILENAME="He3_mac_x64_${REMOTE_VERSION}.dmg"
                    ;;
                arm64)
                    REMOTE_FILENAME="He3_mac_arm64_${REMOTE_VERSION}.dmg"
                    ;;
            esac
            ;;
    esac

    [[ -n "${REMOTE_FILENAME}" ]] && DOWNLOAD_URL="https://he3-1309519128.cos.accelerate.myqcloud.com/${REMOTE_VERSION}/${REMOTE_FILENAME}"

    if [[ -n "${DOWNLOAD_URL}" ]]; then
        colorEcho "${BLUE}Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
        if App_Installer_Download "${DOWNLOAD_URL}" "${WORKDIR}/${DOWNLOAD_FILENAME}"; then
            mkdir -p "${EXEC_INSTALL_PATH}"
            cp -f "${WORKDIR}/${DOWNLOAD_FILENAME}" "${EXEC_INSTALL_PATH}/${DOWNLOAD_FILENAME}"
            echo "${REMOTE_VERSION}" | sudo tee "${EXEC_INSTALL_PATH}/${VERSION_FILENAME}" >/dev/null || true
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit
