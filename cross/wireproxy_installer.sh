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

# [wireproxy - Wireguard client that exposes itself as a socks5 proxy](https://github.com/windtf/wireproxy)
INSTALLER_GITHUB_REPO="windtf/wireproxy"
INSTALLER_BINARY_NAME="wireproxy"
INSTALLER_MATCH_PATTERN="wireproxy*"

INSTALLER_VERSION_TO_FILE="yes"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_BINARY_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    installPrebuiltBinary "${INSTALLER_BINARY_NAME}" "${INSTALLER_GITHUB_REPO}" "${INSTALLER_MATCH_PATTERN}"
fi

: '
# Transfer the WireGuard connection profile to SOCKS5 or HTTP proxy settings
cp ./wgcf-profile.conf /srv/clash/wgcf-proxy.conf

# http creates a http proxy on your LAN, and all traffic would be routed via wireguard
sed -i "1i[http]\nBindAddress = 127.0.0.1:10080" /srv/clash/wgcf-proxy.conf

# Socks5 creates a socks5 proxy on your LAN, and all traffic would be routed via wireguard
sed -i "1i[Socks5]\nBindAddress = 127.0.0.1:10000" /srv/clash/wgcf-proxy.conf

# Run wireproxy with the configuration file
wireproxy -c /srv/clash/wgcf-proxy.conf

# Make wireproxy run in background

wireproxy -c /srv/clash/wgcf-proxy.conf --daemon
'
