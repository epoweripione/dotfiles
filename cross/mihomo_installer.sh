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

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# [mihomo - A simple Python Pydantic model for Honkai: Star Rail parsed data from the Mihomo API](https://github.com/MetaCubeX/mihomo)
INSTALLER_GITHUB_REPO="MetaCubeX/mihomo"
INSTALLER_BINARY_NAME="mihomo"
INSTALLER_MATCH_PATTERN="mihomo*"

INSTALLER_ARCHIVE_EXT="gz"

# geo database
INSTALLER_ADDON_FILES=(
    "Country.mmdb#https://raw.githubusercontent.com/Hackl0us/GeoIP2-CN/release/Country.mmdb#$HOME/.config/mihomo/Country.mmdb"
    "geoip.dat#https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat#$HOME/.config/mihomo/geoip.dat"
    "geosite.dat#https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat#$HOME/.config/mihomo/geosite.dat"
)

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
    if installPrebuiltBinary "${INSTALLER_BINARY_NAME}" "${INSTALLER_GITHUB_REPO}" "${INSTALLER_MATCH_PATTERN}"; then
        # Replace clash with mihomo
        if [[ -d "/srv/clash" ]]; then
            # Remove clash
            systemctl is-enabled "clash" >/dev/null 2>&1 && {
                sudo systemctl stop "clash"
                sudo systemctl disable --now "clash"
                [[ -f "/srv/clash/clash" ]] && sudo rm -f "/srv/clash/clash"
            }

            # Install mihomo if network blocked
            INSTALLER_BINARY_FILE="$(which ${INSTALLER_BINARY_NAME})"
            if [[ -f "${INSTALLER_BINARY_FILE}" ]]; then
                sudo cp -f "${INSTALLER_BINARY_FILE}" "/srv/clash/mihomo"
            fi

            systemctl is-enabled "mihomo" >/dev/null 2>&1 || {
                if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
                    Install_systemd_Service "mihomo" "/srv/clash/mihomo -d /srv/clash" "root"
                fi
            }

            [[ -s "$HOME/.config/mihomo/Country.mmdb" ]] && sudo cp -f "$HOME/.config/mihomo/Country.mmdb" "/srv/clash/Country.mmdb"
            [[ -s "$HOME/.config/mihomo/geoip.dat" ]] && sudo cp -f "$HOME/.config/mihomo/geoip.dat" "/srv/clash/geoip.dat"
            [[ -s "$HOME/.config/mihomo/geosite.dat" ]] && sudo cp -f "$HOME/.config/mihomo/geosite.dat" "/srv/clash/geosite.dat"

            systemctl is-enabled "mihomo" >/dev/null 2>&1 && sudo systemctl restart "mihomo"
        fi
    fi
fi
