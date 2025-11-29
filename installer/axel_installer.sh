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

# [AXEL - Lightweight CLI download accelerator](https://github.com/axel-download-accelerator/axel)
INSTALLER_APP_NAME="axel"
INSTALLER_INSTALL_NAME="axel"
INSTALLER_GITHUB_REPO="axel-download-accelerator/axel"

colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"

App_Installer_Get_Installed_Version "${INSTALLER_APP_NAME}"

if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE} from source..."
    # Pre-requisite packages
    PackagesList=(
        build-essential
        autoconf
        autoconf-archive
        automake
        autopoint
        gcc
        gettext
        libssl-dev
        openssl-devel
        pkg-config
        txt2man
    )
    InstallSystemPackages "" "${PackagesList[@]}"

    if App_Installer_Get_Remote_URL "https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest" "axel-.*\.tar\.gz"; then
        INSTALLER_DOWNLOAD_FILE=$(awk -F"/" '{print $NF}' <<<"${INSTALLER_DOWNLOAD_URL}")
        INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_DOWNLOAD_FILE%%[?#]*}"
        if App_Installer_Download_Extract "${INSTALLER_DOWNLOAD_URL}" "${INSTALLER_DOWNLOAD_FILE}" "${WORKDIR}"; then
            colorEcho "${BLUE}  Compiling ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
            AXEL_EXTRACTED_DIR=$(find "${WORKDIR}" -maxdepth 1 -type d -name "${INSTALLER_APP_NAME}-*")
            mv "${AXEL_EXTRACTED_DIR}" "${WORKDIR}/${INSTALLER_APP_NAME}" && \
                cd "${WORKDIR}/${INSTALLER_APP_NAME}" && \
                ./configure >/dev/null && \
                make >/dev/null && \
                sudo make install >/dev/null

            # Save downloaded file to cache
            App_Installer_Save_to_Cache "${INSTALLER_APP_NAME}" "${INSTALLER_VER_REMOTE}" "${INSTALLER_DOWNLOAD_FILE}"
        else
            colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit
