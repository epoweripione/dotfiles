#!/usr/local/bin/env bash

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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# pacapt - An Arch's pacman-like package manager for some Unices
# https://github.com/icy/pacapt
colorEcho "${BLUE}Checking latest version for ${FUCHSIA}pacapt${BLUE}..."

INSTALLER_CHECK_URL="https://api.github.com/repos/icy/pacapt/releases/latest"
App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"

if [[ -x "$(command -v pacapt)" ]]; then
    ECHO_TYPE="Updating"
    INSTALLER_VER_CURRENT=$(pacapt -V | grep 'version' | cut -d"'" -f2)
else
    INSTALLER_VER_CURRENT="0.0.0"
    ECHO_TYPE="Installing"
fi

# termux: PREFIX="/data/data/com.termux/files/usr"
if [[ -z "${PREFIX}" ]]; then
    PREFIX="/usr/local"
    INSTALL_PACMAN_TO="/usr/bin"
else
    INSTALL_PACMAN_TO="${PREFIX}/bin"
fi

[[ "$(readlink -f /usr/bin/pacman)" == "/usr/bin/pacapt" ]] && \
    sudo rm -f "/usr/bin/pacman" && sudo rm -f "/usr/bin/pacapt"

if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
    colorEcho "${BLUE}  ${ECHO_TYPE} ${FUCHSIA}pacapt ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/pacapt"
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/icy/pacapt/raw/ng/pacapt"
    colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
    sudo curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        INSTALLER_DOWNLOAD_URL="${INSTALLER_DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        sudo mv -f "${INSTALLER_DOWNLOAD_FILE}" "${PREFIX}/bin/pacapt" && \
            sudo chmod 755 "${PREFIX}/bin/pacapt" && \
            sudo ln -sv "${PREFIX}/bin/pacapt" "${INSTALL_PACMAN_TO}/pacman" || true
    fi
fi