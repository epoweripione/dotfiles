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

# [mihomo - A simple Python Pydantic model for Honkai: Star Rail parsed data from the Mihomo API](https://github.com/MetaCubeX/mihomo)
INSTALLER_GITHUB_REPO="MetaCubeX/mihomo"
INSTALLER_BINARY_NAME="mihomo"
INSTALLER_MATCH_PATTERN="mihomo*"

INSTALLER_ARCHIVE_EXT="gz"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_BINARY_NAME} -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
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
        # geo database
        colorEcho "${BLUE}  Installing ${FUCHSIA}geo database${BLUE}..."
        mkdir -p "$HOME/.config/mihomo"

        MMDB_URL="https://raw.githubusercontent.com/Hackl0us/GeoIP2-CN/release/Country.mmdb"
        MMDB_FILE="${WORKDIR}/Country.mmdb"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${MMDB_FILE}" "${MMDB_URL}" && \
            cp -f "${MMDB_FILE}" "$HOME/.config/mihomo/Country.mmdb"

        GEOIP_URL="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat"
        GEOIP_FILE="${WORKDIR}/geoip.dat"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${GEOIP_FILE}" "${GEOIP_URL}" && \
            cp -f "${GEOIP_FILE}" "$HOME/.config/mihomo/geoip.dat"

        GEOSITE_URL="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
        GEOSITE_FILE="${WORKDIR}/geosite.dat"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${GEOSITE_FILE}" "${GEOSITE_URL}" && \
            cp -f "${GEOSITE_FILE}" "$HOME/.config/mihomo/geosite.dat"

        # Replace clash with mihomo
        if [[ -d "/srv/clash" ]]; then
            INSTALLER_BINARY_FILE="$(which ${INSTALLER_BINARY_NAME})"
            if [[ -f "${INSTALLER_BINARY_FILE}" ]]; then
                [[ -f "/srv/clash/clash" ]] && sudo rm -f "/srv/clash/clash"
                sudo cp -f "${INSTALLER_BINARY_FILE}" "/srv/clash/clash"
            fi

            [[ -s "${MMDB_FILE}" ]] && sudo cp -f "${MMDB_FILE}" "/srv/clash/Country.mmdb"
            [[ -s "${GEOIP_FILE}" ]] && sudo cp -f "${GEOIP_FILE}" "/srv/clash/geoip.dat"
            [[ -s "${GEOSITE_FILE}" ]] && sudo cp -f "${GEOSITE_FILE}" "/srv/clash/geosite.dat"

            systemctl is-enabled clash >/dev/null 2>&1 && sudo systemctl restart clash
        fi
    fi
fi
