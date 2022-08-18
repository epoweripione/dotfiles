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

# Tig: text-mode interface for Git
# http://jonas.github.io/tig/
APP_INSTALL_NAME="tig"
GITHUB_REPO_NAME="jonas/tig"

EXEC_INSTALL_NAME="tig"

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} --version | grep -Eo '([0-9]{1,}\.)+[0-9a-zA-Z]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."
    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" \
                        | jq -r '.tag_name//empty' 2>/dev/null \
                        | grep -Eo '([0-9]{1,}\.)+[0-9a-zA-Z]{1,}' \
                        | head -n1 \
                    )
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE} from source..."
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
        for TargetPackage in "${PackagesList[@]}"; do
            if checkPackageNeedInstall "${TargetPackage}"; then
                colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
                sudo pacman --noconfirm -S "${TargetPackage}"
            fi
        done
    fi

    # Git_Clone_Update_Branch "${GITHUB_REPO_NAME}" "$HOME/${APP_INSTALL_NAME}"
    # if [[ -d "$HOME/${APP_INSTALL_NAME}" ]]; then
    #     cd "$HOME/${APP_INSTALL_NAME}" && \
    #         make configure >/dev/null && \
    #         ./configure >/dev/null && \
    #         make prefix=/usr/local >/dev/null && \
    #         sudo make install prefix=/usr/local >/dev/null
    # fi

    REMOTE_FILENAME="${EXEC_INSTALL_NAME}-${REMOTE_VERSION}.tar.gz"
    DOWNLOAD_FILENAME="${WORKDIR}/${REMOTE_FILENAME}"

    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${GITHUB_REPO_NAME}/releases/download/${EXEC_INSTALL_NAME}-${REMOTE_VERSION}/${REMOTE_FILENAME}"
    colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -N -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        tar -xzf "${DOWNLOAD_FILENAME}" -C "${WORKDIR}"
    fi

    if [[ -d "${WORKDIR}/${EXEC_INSTALL_NAME}-${REMOTE_VERSION}" ]]; then
        cd "${WORKDIR}/${EXEC_INSTALL_NAME}-${REMOTE_VERSION}" && \
            make configure >/dev/null && \
            ./configure >/dev/null && \
            make prefix=/usr/local >/dev/null && \
            sudo make install prefix=/usr/local >/dev/null
    fi
fi

cd "${CURRENT_DIR}" || exit
