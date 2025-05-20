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
INSTALLER_APP_NAME="He3"

INSTALLER_INSTALL_PATH="$HOME/Applications"

INSTALLER_DOWNLOAD_FILE="He3.AppImage"
INSTALLER_VER_FILE="${INSTALLER_DOWNLOAD_FILE}.version"

if [[ -f "${INSTALLER_INSTALL_PATH}/${INSTALLER_DOWNLOAD_FILE}" ]]; then
    INSTALLER_IS_UPDATE="yes"
    [[ -s "${INSTALLER_INSTALL_PATH}/${INSTALLER_VER_FILE}" ]] && INSTALLER_VER_CURRENT=$(head -n1 "${INSTALLER_INSTALL_PATH}/${INSTALLER_VER_FILE}")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

# INSTALLER_VER_REMOTE="1.2.9"
if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://raw.githubusercontent.com/he3-app/homebrew-he3/main/Casks/he3.rb"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}" "version.*"
    version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}" && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_VDIS}" ]] && get_sysArch

    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_VDIS}" in
                64)
                    INSTALLER_FILE_NAME="He3_linux_x86_64_${INSTALLER_VER_REMOTE}.AppImage"
                    ;;
                arm64)
                    INSTALLER_FILE_NAME="He3_linux_arm64_${INSTALLER_VER_REMOTE}.AppImage"
                    ;;
            esac
            ;;
        darwin)
            case "${OS_INFO_VDIS}" in
                64)
                    INSTALLER_FILE_NAME="He3_mac_x64_${INSTALLER_VER_REMOTE}.dmg"
                    ;;
                arm64)
                    INSTALLER_FILE_NAME="He3_mac_arm64_${INSTALLER_VER_REMOTE}.dmg"
                    ;;
            esac
            ;;
    esac

    [[ -n "${INSTALLER_FILE_NAME}" ]] && INSTALLER_DOWNLOAD_URL="https://dl.he3app.com/${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"

    if [[ -n "${INSTALLER_DOWNLOAD_URL}" ]]; then
        colorEcho "${BLUE}Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        if App_Installer_Download "${INSTALLER_DOWNLOAD_URL}" "${WORKDIR}/${INSTALLER_DOWNLOAD_FILE}"; then
            mkdir -p "${INSTALLER_INSTALL_PATH}"
            cp -f "${WORKDIR}/${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_INSTALL_PATH}/${INSTALLER_DOWNLOAD_FILE}"
            echo "${INSTALLER_VER_REMOTE}" | sudo tee "${INSTALLER_INSTALL_PATH}/${INSTALLER_VER_FILE}" >/dev/null || true
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit
