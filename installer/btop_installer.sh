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

# BTOP++: A monitor of resources
# https://github.com/aristocratos/btop
INSTALLER_APP_NAME="btop"
INSTALLER_GITHUB_REPO="aristocratos/btop"

INSTALLER_INSTALL_NAME="btop"

INSTALLER_ARCHIVE_EXT="tbz"
INSTALLER_ARCHIVE_EXEC_DIR="btop"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
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

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch
    [[ -z "${OS_INFO_FLOAT}" ]] && get_arch_float

    case "${OS_INFO_ARCH}" in
        amd64)
            INSTALLER_FILE_NAME="btop-x86_64-${OS_INFO_TYPE}-musl.${INSTALLER_ARCHIVE_EXT}"
            ;;
        386)
            INSTALLER_FILE_NAME="btop-i686-${OS_INFO_TYPE}-musl.${INSTALLER_ARCHIVE_EXT}"
            ;;
        arm64)
            INSTALLER_FILE_NAME="btop-aarch64-${OS_INFO_TYPE}-musl.${INSTALLER_ARCHIVE_EXT}"
            ;;
        arm)
            [[ "${OS_INFO_FLOAT}" == "hardfloat" ]] && \
                INSTALLER_FILE_NAME="btop-armv7r-${OS_INFO_TYPE}-musleabihf.${INSTALLER_ARCHIVE_EXT}" || \
                INSTALLER_FILE_NAME="btop-armv7m-${OS_INFO_TYPE}-musleabi.${INSTALLER_ARCHIVE_EXT}"
            ;;
        *)
            INSTALLER_FILE_NAME="btop-${OS_INFO_ARCH}-${OS_INFO_TYPE}-musl.${INSTALLER_ARCHIVE_EXT}"
            ;;
    esac

    [[ -z "${INSTALLER_FILE_NAME}" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    if App_Installer_Get_Remote_URL "https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest" "${INSTALLER_INSTALL_NAME}-.*\.${INSTALLER_ARCHIVE_EXT}"; then
        if App_Installer_Download_Extract "${INSTALLER_DOWNLOAD_URL}" "" "${WORKDIR}"; then
            # Install
            [[ -n "${INSTALLER_ARCHIVE_EXEC_DIR}" ]] && INSTALLER_ARCHIVE_EXEC_DIR=$(find "${WORKDIR}" -type d -name "${INSTALLER_ARCHIVE_EXEC_DIR}")
            [[ -z "${INSTALLER_ARCHIVE_EXEC_DIR}" || ! -d "${INSTALLER_ARCHIVE_EXEC_DIR}" ]] && INSTALLER_ARCHIVE_EXEC_DIR=${WORKDIR}

            if [[ -d "${INSTALLER_ARCHIVE_EXEC_DIR}" ]]; then
                cd  "${INSTALLER_ARCHIVE_EXEC_DIR}" && sudo make install && sudo make setuid
            fi
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit