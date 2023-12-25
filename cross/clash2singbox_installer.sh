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

# [clash2singbox](https://github.com/xmdhs/clash2singbox)
INSTALLER_GITHUB_REPO="xmdhs/clash2singbox"
INSTALLER_BINARY_NAME="clash2singbox"
INSTALLER_MATCH_PATTERN="clash2singbox-*"

INSTALLER_VER_FILE="${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}.version"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    [[ -s "${INSTALLER_VER_FILE}" ]] && INSTALLER_VER_CURRENT=$(head -n1 "${INSTALLER_VER_FILE}")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_BINARY_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    if intallPrebuiltBinary "${INSTALLER_BINARY_NAME}" "${INSTALLER_GITHUB_REPO}" "${INSTALLER_MATCH_PATTERN}"; then
        GEOIP_URL="https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db"
        GEOIP_FILE="${WORKDIR}/geoip.dat"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${GEOIP_FILE}" "${GEOIP_URL}" && \
            cp -f "${GEOIP_FILE}" "$HOME/.config/singbox/geoip.dat"

        GEOSITE_URL="https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db"
        GEOSITE_FILE="${WORKDIR}/geosite.dat"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${GEOSITE_FILE}" "${GEOSITE_URL}" && \
            cp -f "${GEOSITE_FILE}" "$HOME/.config/singbox/geosite.dat"

        if [[ -d "/srv/singbox" ]]; then
            [[ -s "${GEOIP_FILE}" ]] && sudo cp -f "${GEOIP_FILE}" "/srv/singbox/geoip.dat"
            [[ -s "${GEOSITE_FILE}" ]] && sudo cp -f "${GEOSITE_FILE}" "/srv/singbox/geosite.dat"
        fi
    fi
fi
