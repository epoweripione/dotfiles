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

# [pg_format - PostgreSQL SQL syntax beautifier](https://github.com/darold/pgFormatter)
INSTALLER_APP_NAME="pgFormatter"
INSTALLER_GITHUB_REPO="darold/pgFormatter"

INSTALLER_INSTALL_NAME="pg_format"

INSTALLER_ARCHIVE_EXT="tar.gz"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    if [[ -x "$(command -v pacman)" ]]; then
        # Pre-requisite packages
        PackagesList=(
            perl
            perl-autodie
            perl-cgi
            perl-json
            libcgi-pm-perl
            libjson-perl
        )
        InstallSystemPackages "" "${PackagesList[@]}"
    fi

    INSTALLER_DOWNLOAD_URL="https://github.com/darold/pgFormatter/archive/refs/tags/v${INSTALLER_VER_REMOTE}.tar.gz"
    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/pgformatter-${INSTALLER_VER_REMOTE}.tar.gz"
    if curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"; then
        tar -xzf "${INSTALLER_DOWNLOAD_FILE}" -C "${WORKDIR}" && \
            cd "${WORKDIR}/pgFormatter-${INSTALLER_VER_REMOTE}/" && \
            perl Makefile.PL && \
            make && sudo make install
    fi
fi

cd "${CURRENT_DIR}" || exit
