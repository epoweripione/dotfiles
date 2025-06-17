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

# [dysk - A linux utility to get information on filesystems, like df but better](https://github.com/Canop/dysk)
INSTALLER_APP_NAME="dysk"
INSTALLER_INSTALL_NAME="dysk"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_INSTALL_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
    INSTALLER_CHECK_URL="https://dystroy.org/dysk/download/version"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}" '([0-9]{1,}\.)+[0-9]{1,}'
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    INSTALLER_CHECK_URL="https://dystroy.org/dysk/install/"
    INSTALLER_REMOTE_CONTENT=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" 2>/dev/null)
    if [[ -n "${INSTALLER_REMOTE_CONTENT}" ]]; then
        if App_Installer_Get_Remote_URL "${INSTALLER_CHECK_URL}" 'download\/.*\/dysk' '([0-9]{1,}\.)+[0-9]{1,}'; then
            [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
            [[ -z "${OS_INFO_ARCH}" ]] && get_arch
            INSTALLER_FILE_NAME="${INSTALLER_APP_NAME}-${INSTALLER_VER_REMOTE}-${OS_INFO_TYPE}-${OS_INFO_ARCH}"
            INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_FILE_NAME}"
            if ! App_Installer_Install "${INSTALLER_CHECK_URL}"; then
                colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
            fi
        else
            installBuildBinary "${INSTALLER_APP_NAME}" "${INSTALLER_INSTALL_NAME}" "cargo"
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit
