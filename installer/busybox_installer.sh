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

# https://www.busybox.net/
INSTALLER_APP_NAME="busybox"
INSTALLER_INSTALL_NAME="busybox"

colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" -N https://www.busybox.net/downloads/ \
    | grep -Eo 'busybox-([0-9]{1,}\.)+[0-9]{1,}' | sort -rV | head -n1 | cut -d'-' -f2)

# http://mybookworld.wikidot.com/compile-nano-from-source
if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE} from source..."
    INSTALLER_FILE_NAME="${INSTALLER_APP_NAME}-${INSTALLER_VER_REMOTE}.tar.bz2"
    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_APP_NAME}.tar.bz2"

    INSTALLER_DOWNLOAD_URL="https://www.busybox.net/downloads/${INSTALLER_FILE_NAME}"

    wget -O "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" && \
        tar -xjf "${INSTALLER_DOWNLOAD_FILE}" -C "${WORKDIR}" && \
        mv "${WORKDIR}"/${INSTALLER_APP_NAME}-* "${WORKDIR}/${INSTALLER_APP_NAME}"

    if [[ -d "${WORKDIR}/${INSTALLER_APP_NAME}" ]]; then
        colorEcho "${BLUE}  Compiling ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
        cd "${WORKDIR}/${INSTALLER_APP_NAME}" && \
            make defconfig >/dev/null && \
            make >/dev/null && \
            sudo cp -f "${WORKDIR}/${INSTALLER_APP_NAME}/${INSTALLER_INSTALL_NAME}" "/usr/local/bin" && \
            sudo chmod +x "/usr/local/bin/${INSTALLER_INSTALL_NAME}"
    fi
fi

# if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
#     mkdir -p "$HOME/busybox"
#     for i in $(busybox --list); do
#         ln -s busybox "$HOME/busybox/$i"
#     done
# fi

cd "${CURRENT_DIR}" || exit