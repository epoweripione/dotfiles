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

# [sing-box: The universal proxy platform](https://sing-box.sagernet.org/)
INSTALLER_APP_NAME="sing-box"
INSTALLER_GITHUB_REPO="SagerNet/sing-box"

INSTALLER_INSTALL_NAME="sing-box"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_ARCHIVE_EXEC_DIR="sing-box-*"
INSTALLER_ARCHIVE_EXEC_NAME="sing-box"

# geo database
INSTALLER_ADDON_FILES=(
    "Country.mmdb#https://raw.githubusercontent.com/Hackl0us/GeoIP2-CN/release/Country.mmdb#$HOME/.config/singbox/Country.mmdb"
    "geoip.dat#https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db#$HOME/.config/singbox/geoip.dat"
    "geosite.dat#https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db#$HOME/.config/singbox/geosite.dat"
)

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if App_Installer_Install; then
    if [[ -d "/srv/singbox" ]]; then
        [[ -s "$HOME/.config/singbox/Country.mmdb" ]] && sudo cp -f "$HOME/.config/singbox/Country.mmdb" "/srv/singbox/Country.mmdb"
        [[ -s "$HOME/.config/singbox/geoip.dat" ]] && sudo cp -f "$HOME/.config/singbox/geoip.dat" "/srv/singbox/geoip.dat"
        [[ -s "$HOME/.config/singbox/geosite.dat" ]] && sudo cp -f "$HOME/.config/singbox/geosite.dat" "/srv/singbox/geosite.dat"
    fi
else
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi

cd "${CURRENT_DIR}" || exit
