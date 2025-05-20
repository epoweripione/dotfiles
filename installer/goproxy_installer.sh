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

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch

# goproxy
# https://github.com/snail007/goproxy
INSTALLER_APP_NAME="goproxy"

if [[ -d "/etc/proxy" && -x "$(command -v proxy)" ]]; then
    INSTALLER_VER_CURRENT=$(proxy --version 2>&1 | cut -d'_' -f2)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/snail007/goproxy/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    # curl "${CURL_DOWNLOAD_OPTS[@]}" \
    #     https://raw.githubusercontent.com/snail007/goproxy/master/install_auto.sh \
    # | sudo bash
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/snail007/goproxy/releases/download/v${INSTALLER_VER_REMOTE}/proxy-${OS_INFO_TYPE}-${OS_INFO_ARCH}.tar.gz"
    cd "${WORKDIR}" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o proxy-linux-amd64.tar.gz "${INSTALLER_DOWNLOAD_URL}" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" "https://raw.githubusercontent.com/snail007/goproxy/master/install.sh" | sudo bash
fi

if [[ -d "/etc/proxy" && -x "$(command -v proxy)" ]]; then
    if [[ ! -e "/etc/proxy/proxy.crt" ]]; then
        cd /etc/proxy && proxy keygen -C proxy -d 365 >/dev/null 2>&1 
    fi
fi


App_Installer_Reset
# ProxyAdmin
# https://github.com/snail007/proxy_admin_free
# config file: /etc/gpa/app.toml
# http://127.0.0.1:32080
# user/pwd: root/123
# proxy-admin install
# proxy-admin uninstall
# proxy-admin start
# proxy-admin stop
# proxy-admin restart
if [[ -x "$(command -v proxy-admin)" ]]; then
    [[ -s "/etc/gpa/.version" ]] && INSTALLER_VER_CURRENT=$(head -n1 /etc/gpa/.version)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    INSTALLER_CHECK_URL="https://api.github.com/repos/snail007/proxy_admin_free/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}ProxyAdmin ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    curl "${CURL_DOWNLOAD_OPTS[@]}" "https://raw.githubusercontent.com/snail007/proxy_admin_free/master/install_auto.sh" | sudo bash && \
        echo "${INSTALLER_VER_REMOTE}" | sudo tee "/etc/gpa/.version" >/dev/null
fi

cd "${CURRENT_DIR}" || exit