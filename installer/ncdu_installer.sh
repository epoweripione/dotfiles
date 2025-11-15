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

# [NCurses Disk Usage](https://dev.yorhel.nl/ncdu)
INSTALLER_APP_NAME="ncdu"
INSTALLER_INSTALL_NAME="ncdu"
INSTALLER_ARCHIVE_EXT="tar.gz"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_INSTALL_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
    INSTALLER_CHECK_URL="https://dev.yorhel.nl/ncdu"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}" "ncdu-.*\.tar\.gz"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    if App_Installer_Get_Remote_URL "${INSTALLER_CHECK_URL}" "ncdu-${INSTALLER_VER_REMOTE//./\\.}\.tar\.gz" "ncdu-.*\.tar\.gz"; then
        INSTALLER_DOWNLOAD_URL="https://dev.yorhel.nl/download/${INSTALLER_DOWNLOAD_URL}"

        INSTALLER_DOWNLOAD_FILE=$(awk -F"/" '{print $NF}' <<<"${INSTALLER_DOWNLOAD_URL}")
        INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_DOWNLOAD_FILE%%[?#]*}"
        if App_Installer_Download_Extract "${INSTALLER_DOWNLOAD_URL}" "${INSTALLER_DOWNLOAD_FILE}" "${WORKDIR}"; then
            NCDU_EXTRACTED_DIR=$(find "${WORKDIR}" -maxdepth 1 -type d -name "${INSTALLER_APP_NAME}-*")
            mv "${NCDU_EXTRACTED_DIR}" "${WORKDIR}/${INSTALLER_APP_NAME}"
            [[ -f "${WORKDIR}/${INSTALLER_APP_NAME}/build.zig" ]] && INSTALLER_INSTALL_METHOD="build"
        fi
    fi
fi

if [[ "${INSTALLER_INSTALL_METHOD}" == "build" ]]; then
    if [[ ! -x "$(command -v zig)" && "$(command -v mise)" ]]; then
        mise install zig
        mise use --global zig
    fi

    if [[ -x "$(command -v zig)" ]]; then
        # Pre-requisite packages
        PackagesList=(
            "libncurses-dev"
            "libncursesw-dev"
            "libncurses5-dev"
            "libncursesw5-dev"
            "libzstd"
            "libzstd-dev"
            "libzstd-devel"
            "ncurses"
            "ncurses-devel"
        )
        InstallSystemPackages "" "${PackagesList[@]}"

        colorEcho "${BLUE}  Compiling ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
        cd "${WORKDIR}/${INSTALLER_APP_NAME}" && \
            make && \
            sudo install -m0755 zig-out/bin/ncdu "${INSTALLER_INSTALL_PATH}" &&
            sudo install -m0644 ncdu.1 "${INSTALLER_MANPAGE_PATH}/man1"

        # Save downloaded file to cache
        App_Installer_Save_to_Cache "${INSTALLER_APP_NAME}" "${INSTALLER_VER_REMOTE}" "${INSTALLER_DOWNLOAD_FILE}"
    else
        INSTALLER_INSTALL_METHOD="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" && "${INSTALLER_INSTALL_METHOD}" != "build" ]]; then
    if App_Installer_Get_Remote_URL "${INSTALLER_CHECK_URL}" 'ncdu-[^<>:;,?"*|/]+\.tar\.gz' "ncdu-.*\.tar\.gz"; then
        INSTALLER_DOWNLOAD_URL="https://dev.yorhel.nl/download/${INSTALLER_DOWNLOAD_URL}"
        if ! App_Installer_Install "${INSTALLER_CHECK_URL}"; then
            colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit
