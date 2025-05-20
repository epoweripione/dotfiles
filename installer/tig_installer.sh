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

# Tig: text-mode interface for Git
# http://jonas.github.io/tig/
INSTALLER_APP_NAME="tig"
INSTALLER_GITHUB_REPO="jonas/tig"

INSTALLER_INSTALL_NAME="tig"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version | grep -Eo '([0-9]{1,}\.)+[0-9a-zA-Z]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" \
                        | jq -r '.tag_name//empty' 2>/dev/null \
                        | grep -Eo '([0-9]{1,}\.)+[0-9a-zA-Z]{1,}' \
                        | head -n1 \
                    )
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE} from source..."
    if [[ -x "$(command -v pacman)" ]]; then
        # Pre-requisite packages
        PackagesList=(
            autoconf
            build-essential
            gcc
            make
            libevent
            libevent-dev
            libevent-devel
            ncurses
            libncurses-dev
            libncursesw-dev
            libncurses5-dev
            libncursesw5-dev
            ncurses-devel
            readline
        )
        InstallSystemPackages "" "${PackagesList[@]}"
    fi

    # Git_Clone_Update_Branch "${INSTALLER_GITHUB_REPO}" "$HOME/${INSTALLER_APP_NAME}"
    # if [[ -d "$HOME/${INSTALLER_APP_NAME}" ]]; then
    #     cd "$HOME/${INSTALLER_APP_NAME}" && \
    #         make configure >/dev/null && \
    #         ./configure >/dev/null && \
    #         make prefix=/usr/local >/dev/null && \
    #         sudo make install prefix=/usr/local >/dev/null
    # fi

    INSTALLER_FILE_NAME="${INSTALLER_INSTALL_NAME}-${INSTALLER_VER_REMOTE}.tar.gz"
    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_FILE_NAME}"

    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${INSTALLER_GITHUB_REPO}/releases/download/${INSTALLER_INSTALL_NAME}-${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
    colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        INSTALLER_DOWNLOAD_URL="${INSTALLER_DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        tar -xzf "${INSTALLER_DOWNLOAD_FILE}" -C "${WORKDIR}"
    fi

    if [[ -d "${WORKDIR}/${INSTALLER_INSTALL_NAME}-${INSTALLER_VER_REMOTE}" ]]; then
        cd "${WORKDIR}/${INSTALLER_INSTALL_NAME}-${INSTALLER_VER_REMOTE}" && \
            make configure >/dev/null && \
            ./configure >/dev/null && \
            make prefix=/usr/local >/dev/null && \
            sudo make install prefix=/usr/local >/dev/null
    fi
fi

cd "${CURRENT_DIR}" || exit
