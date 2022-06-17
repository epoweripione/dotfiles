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

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_VDIS}" ]] && get_sysArch

# bat
# https://github.com/sharkdp/bat
APP_INSTALL_NAME="bat"
ARCHIVE_EXT="tar.gz"

ARCHIVE_EXEC_DIR="bat-*"
ARCHIVE_EXEC_NAME="bat"

EXEC_INSTALL_PATH="/usr/local/bin"
EXEC_INSTALL_NAME="bat"

colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

CHECK_URL="https://api.github.com/repos/sharkdp/bat/releases/latest"
REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)

REMOTE_FILENAME=""
case "${OS_INFO_TYPE}" in
    linux)
        case "${OS_INFO_VDIS}" in
            32)
                REMOTE_FILENAME=bat-v${REMOTE_VERSION}-i686-unknown-linux-musl.${ARCHIVE_EXT}
                ;;
            64)
                REMOTE_FILENAME=bat-v${REMOTE_VERSION}-x86_64-unknown-linux-musl.${ARCHIVE_EXT}
                ;;
            arm)
                REMOTE_FILENAME=bat-v${REMOTE_VERSION}-arm-unknown-linux-gnueabihf.${ARCHIVE_EXT}
                ;;
            arm64)
                REMOTE_FILENAME=bat-v${REMOTE_VERSION}-aarch64-unknown-linux-gnu.${ARCHIVE_EXT}
                ;;
        esac
        ;;
    darwin)
        REMOTE_FILENAME=bat-v${REMOTE_VERSION}-x86_64-apple-darwin.${ARCHIVE_EXT}
        ;;
    windows)
        ARCHIVE_EXT="zip"
        REMOTE_FILENAME=bat-v${REMOTE_VERSION}-x86_64-pc-windows-msvc.${ARCHIVE_EXT}
        ;;
esac

if [[ -x "$(command -v bat)" ]]; then
    CURRENT_VERSION=v$(bat --version | cut -d' ' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        REMOTE_FILENAME=""
    fi
fi

if [[ -n "$REMOTE_VERSION" && -n "$REMOTE_FILENAME" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."

    DOWNLOAD_FILENAME="${WORKDIR}/bat.${ARCHIVE_EXT}"
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/sharkdp/bat/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
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
        [[ -s "/usr/bin/bat" ]] && sudo rm -f "/usr/bin/bat"
        [[ -d "/usr/local/bat" ]] && sudo rm -rf "/usr/local/bat"

        tar -xzf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}"

        [[ -n "${ARCHIVE_EXEC_DIR}" ]] && ARCHIVE_EXEC_DIR=$(find "${WORKDIR}" -type d -name "${ARCHIVE_EXEC_DIR}")
        [[ -z "${ARCHIVE_EXEC_DIR}" || ! -d "${ARCHIVE_EXEC_DIR}" ]] && ARCHIVE_EXEC_DIR=${WORKDIR}

        if [[ -s "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}" ]]; then
            sudo cp -f "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}" "${EXEC_INSTALL_PATH}/${EXEC_INSTALL_NAME}" && \
                sudo cp -f "${ARCHIVE_EXEC_DIR}/${ARCHIVE_EXEC_NAME}.1" "/usr/share/man/man1" && \
                sudo cp -f "${ARCHIVE_EXEC_DIR}/autocomplete/${ARCHIVE_EXEC_NAME}.zsh" "/usr/local/share/zsh/site-functions" && \
                sudo chmod 644 "/usr/local/share/zsh/site-functions/${ARCHIVE_EXEC_NAME}.zsh" && \
                sudo chown "$(id -u)":"$(id -g)" "/usr/local/share/zsh/site-functions/${ARCHIVE_EXEC_NAME}.zsh"
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit