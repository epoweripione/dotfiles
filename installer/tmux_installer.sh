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

if [[ -n "$TMUX" ]]; then
    colorEcho "${RED}Can't build & install ${FUCHSIA}tmux${RED} in a ${YELLOW}tmux${RED} session!"
    exit 1
fi

App_Installer_Reset

# https://github.com/tmux/tmux
INSTALLER_APP_NAME="tmux"
INSTALLER_GITHUB_REPO="tmux/tmux"

INSTALLER_INSTALL_NAME="tmux"

colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null)

# http://mybookworld.wikidot.com/compile-tmux-from-source
if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -V | grep -Eo '([0-9]{1,}\.)+[0-9a-zA-Z]{1,}' | head -n1)
fi

if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE} from source..."
    if [[ -x "$(command -v pacman)" ]]; then
        # Remove installed old version
        if checkPackageInstalled "${INSTALLER_APP_NAME}"; then
            INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -V | grep -Eo '([0-9]{1,}\.)+[0-9a-zA-Z]{1,}' | head -n1)
            if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
                colorEcho "${BLUE}  Removing ${FUCHSIA}${INSTALLER_APP_NAME}${YELLOW} ${INSTALLER_VER_CURRENT}${BLUE}..."
                sudo pacman --noconfirm -R "${INSTALLER_APP_NAME}"
                sudo pacman --noconfirm -Rn "${INSTALLER_APP_NAME}" || true
            fi
        fi

        # Pre-requisite packages
        PackagesList=(
            build-essential
            gcc
            make
            bison
            pkg-config
            libevent
            libevent-dev
            libevent-devel
            ncurses
            libncurses-dev
            libncursesw-dev
            libncurses5-dev
            libncursesw5-dev
            ncurses-devel
        )
        for TargetPackage in "${PackagesList[@]}"; do
            if checkPackageNeedInstall "${TargetPackage}"; then
                colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
                sudo pacman --noconfirm -S "${TargetPackage}"
            fi
        done
    fi

    ## tmux: error while loading shared libraries: libevent_core-2.1.so.6: cannot open shared object file: No such file or directory
    # FILE_LIBC=$(find /usr /lib -name "libevent_core-2.1.so.6" | head -n1)
    # if [[ -z "${FILE_LIBC}" ]]; then
    #     FILE_LIBC=$(find /usr /lib -name "libevent_core.so" | head -n1)
    #     [[ -n "${FILE_LIBC}" ]] && sudo ln -s "${FILE_LIBC}" "$(dirname ${FILE_LIBC})/libevent_core-2.1.so.6"
    # fi

    INSTALLER_FILE_NAME="${INSTALLER_APP_NAME}-${INSTALLER_VER_REMOTE}.tar.gz"
    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_APP_NAME}.tar.gz"

    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${INSTALLER_GITHUB_REPO}/releases/download/${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
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
        tar -xzf "${INSTALLER_DOWNLOAD_FILE}" -C "${WORKDIR}" && \
            mv "${WORKDIR}"/${INSTALLER_APP_NAME}-* "${WORKDIR}/${INSTALLER_APP_NAME}"
    fi

    if [[ -d "${WORKDIR}/${INSTALLER_APP_NAME}" ]]; then
        colorEcho "${BLUE}  Compiling ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
        cd "${WORKDIR}/${INSTALLER_APP_NAME}" && \
            ./configure --prefix=/usr >/dev/null && \
            make >/dev/null && \
            sudo make install >/dev/null
    fi
fi


cd "${CURRENT_DIR}" || exit