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

# cgit: github.com.cnpmjs.org
# https://github.com/killf/cgit
APP_INSTALL_NAME="cgit"
GITHUB_REPO_NAME="killf/cgit"

EXEC_INSTALL_PATH="/usr/local/bin"
EXEC_INSTALL_NAME="cgit"

REMOTE_FILENAME=""

IS_INSTALL="yes"
IS_UPDATE="no"

DOWNLOAD_FILENAME="${WORKDIR}/${EXEC_INSTALL_NAME}"

CURRENT_VERSION="0.0.0"
VERSION_FILENAME="${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}.version"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    [[ -s "${VERSION_FILENAME}" ]] && CURRENT_VERSION=$(head -n1 "${VERSION_FILENAME}")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' | cut -d'v' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    case "${OS_INFO_TYPE}" in
        linux)
            case "${OS_INFO_ARCH}" in
                arm | arm64)
                    REMOTE_FILENAME="http://cgit.killf.info/cgit_arm_latest"
                    ;;
                *)
                    REMOTE_FILENAME="http://cgit.killf.info/cgit_linux_latest"
                    ;;
            esac
            ;;
        darwin)
            REMOTE_FILENAME="http://cgit.killf.info/cgit_mac_latest"
            ;;
        windows)
            REMOTE_FILENAME="http://cgit.killf.info/cgit.exe"
            ;;
    esac

    [[ -z "${REMOTE_FILENAME}" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    DOWNLOAD_URL="${REMOTE_FILENAME}"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        sudo mv -f "${DOWNLOAD_FILENAME}" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
            sudo chmod +x "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
            [[ -n "${VERSION_FILENAME}" ]] && echo "${REMOTE_VERSION}" | sudo tee "${VERSION_FILENAME}" >/dev/null || true
    fi
fi


cd "${CURRENT_DIR}" || exit