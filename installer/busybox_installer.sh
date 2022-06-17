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


[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

# https://www.busybox.net/
APP_INSTALL_NAME="busybox"
EXEC_INSTALL_NAME="busybox"

colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."
REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" -N https://www.busybox.net/downloads/ \
    | grep -Eo 'busybox-([0-9]{1,}\.)+[0-9]{1,}' | sort -rV | head -n1 | cut -d'-' -f2)

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"

# http://mybookworld.wikidot.com/compile-nano-from-source
if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if version_gt "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE} from source..."
    REMOTE_FILENAME="${APP_INSTALL_NAME}-${REMOTE_VERSION}.tar.bz2"
    DOWNLOAD_FILENAME="${WORKDIR}/${APP_INSTALL_NAME}.tar.bz2"

    DOWNLOAD_URL="https://www.busybox.net/downloads/${REMOTE_FILENAME}"

    wget -O "${DOWNLOAD_FILENAME}" "$DOWNLOAD_URL" && \
        tar -xjf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}" && \
        mv "${WORKDIR}"/${APP_INSTALL_NAME}-* "${WORKDIR}/${APP_INSTALL_NAME}"

    if [[ -d "${WORKDIR}/${APP_INSTALL_NAME}" ]]; then
        colorEcho "${BLUE}  Compiling ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."
        cd "${WORKDIR}/${APP_INSTALL_NAME}" && \
            make defconfig >/dev/null && \
            make >/dev/null && \
            sudo cp -f "${WORKDIR}/${APP_INSTALL_NAME}/${EXEC_INSTALL_NAME}" "/usr/local/bin" && \
            sudo chmod +x "/usr/local/bin/${EXEC_INSTALL_NAME}"
    fi
fi

# if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
#     mkdir -p "$HOME/busybox"
#     for i in $(busybox --list); do
#         ln -s busybox "$HOME/busybox/$i"
#     done
# fi

cd "${CURRENT_DIR}" || exit