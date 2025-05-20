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

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch

# MinIO - High Performance, Kubernetes Native Object Storage
# https://github.com/minio/minio
INSTALLER_INSTALL_PATH="/usr/local/bin"

DOWNLOAD_DOMAIN="https://dl.min.io"
# [[ "${THE_WORLD_BLOCKED}" == "true" ]] && DOWNLOAD_DOMAIN="http://dl.minio.org.cn"

# MINIO CLIENT
INSTALLER_APP_NAME="mc"
INSTALLER_INSTALL_NAME="mc"
INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_INSTALL_NAME}"

INSTALLER_VER_CURRENT="0.0"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -v | grep -Po -m1 'RELEASE\.[0-9+TZ:-]{2,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
    INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" \
                            -N "${DOWNLOAD_DOMAIN}/client/mc/release/${OS_INFO_TYPE}-${OS_INFO_ARCH}" \
                            | grep -Po -m1 'RELEASE\.[0-9+TZ:-]{2,}' | head -n1)
    [[ -z "${INSTALLER_VER_REMOTE}" ]] && INSTALLER_VER_REMOTE="0.0"

    version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}" && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    INSTALLER_DOWNLOAD_URL="${DOWNLOAD_DOMAIN}/client/mc/release/${OS_INFO_TYPE}-${OS_INFO_ARCH}/${INSTALLER_INSTALL_NAME}"

    colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"
    curl_download_status=$?

    if [[ ${curl_download_status} -eq 0 ]]; then
        sudo cp -f "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}" && \
            sudo chmod +x "${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}"
    fi
fi
