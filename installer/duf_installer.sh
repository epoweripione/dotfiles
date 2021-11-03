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

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_VDIS}" ]] && get_sysArch

# duf
# https://github.com/muesli/duf
APP_INSTALL_NAME="duf"

colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

CHECK_URL="https://api.github.com/repos/muesli/duf/releases/latest"
REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | grep 'tag_name' | cut -d\" -f4 | cut -d'v' -f2)

REMOTE_FILENAME=""
case "${OS_INFO_TYPE}" in
    linux | freebsd | openbsd)
        case "${OS_INFO_VDIS}" in
            32)
                REMOTE_FILENAME=duf_${REMOTE_VERSION}_${OS_INFO_TYPE}_i386.tar.gz
                ;;
            64)
                REMOTE_FILENAME=duf_${REMOTE_VERSION}_${OS_INFO_TYPE}_x86_64.tar.gz
                ;;
            arm)
                REMOTE_FILENAME=duf_${REMOTE_VERSION}_${OS_INFO_TYPE}_armv7.tar.gz
                ;;
            *)
                REMOTE_FILENAME=duf_${REMOTE_VERSION}_${OS_INFO_TYPE}_${OS_INFO_VDIS}.tar.gz
                ;;
        esac
        ;;
    darwin)
        REMOTE_FILENAME=duf_${REMOTE_VERSION}_Darwin_x86_64.tar.gz
        ;;
esac

if [[ -x "$(command -v duf)" ]]; then
    CURRENT_VERSION=$(duf -version | cut -d' ' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        REMOTE_FILENAME=""
    fi
fi

if [[ -n "$REMOTE_VERSION" && -n "$REMOTE_FILENAME" ]]; then
    colorEcho "${BLUE} Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."

    DOWNLOAD_FILENAME="${WORKDIR}/duf.tar.gz"
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/muesli/duf/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
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
        [[ -s "/usr/local/bin/duf" ]] && sudo rm -f "/usr/local/bin/duf"
        [[ -d "/usr/local/duf" ]] && sudo rm -rf "/usr/local/duf"

        tar -xzf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}" && \
            sudo cp -f "${WORKDIR}/duf" "/usr/local/bin/duf"
    fi
fi