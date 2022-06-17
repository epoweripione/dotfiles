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

[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# MinIO - High Performance, Kubernetes Native Object Storage
# https://github.com/minio/minio
EXEC_INSTALL_PATH="/usr/local/bin"

DOWNLOAD_DOMAIN="https://dl.min.io"
# [[ "${THE_WORLD_BLOCKED}" == "true" ]] && DOWNLOAD_DOMAIN="http://dl.minio.org.cn"

# MINIO CLIENT
APP_INSTALL_NAME="mc"
EXEC_INSTALL_NAME="mc"
DOWNLOAD_FILENAME="${WORKDIR}/${EXEC_INSTALL_NAME}"

[[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]] && IS_INSTALL="no" || IS_INSTALL="yes"

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    DOWNLOAD_URL="${DOWNLOAD_DOMAIN}/client/mc/release/${OS_INFO_TYPE}-${OS_INFO_ARCH}/${EXEC_INSTALL_NAME}"

    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
    curl_download_status=$?

    if [[ ${curl_download_status} -eq 0 ]]; then
        sudo cp -f "${DOWNLOAD_FILENAME}" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
            sudo chmod +x "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}"
    fi
fi
