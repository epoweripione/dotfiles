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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch

# goproxy
# https://github.com/snail007/goproxy
APP_INSTALL_NAME="goproxy"

IS_INSTALL="yes"
CURRENT_VERSION="0.0.0"

if [[ -d "/etc/proxy" && -x "$(command -v proxy)" ]]; then
    CURRENT_VERSION=$(proxy --version 2>&1 | cut -d'_' -f2)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/snail007/goproxy/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    # curl "${CURL_DOWNLOAD_OPTS[@]}" \
    #     https://raw.githubusercontent.com/snail007/goproxy/master/install_auto.sh \
    # | sudo bash
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/snail007/goproxy/releases/download/v${REMOTE_VERSION}/proxy-${OS_INFO_TYPE}-${OS_INFO_ARCH}.tar.gz"
    cd "${WORKDIR}" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o proxy-linux-amd64.tar.gz "$DOWNLOAD_URL" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" "https://raw.githubusercontent.com/snail007/goproxy/master/install.sh" | sudo bash
fi

if [[ -d "/etc/proxy" && -x "$(command -v proxy)" ]]; then
    if [[ ! -e "/etc/proxy/proxy.crt" ]]; then
        cd /etc/proxy && proxy keygen -C proxy -d 365 >/dev/null 2>&1 
    fi
fi


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
IS_INSTALL="yes"
CURRENT_VERSION="v0.0"

if [[ -x "$(command -v proxy-admin)" ]]; then
    [[ -s "/etc/gpa/.version" ]] && CURRENT_VERSION=$(head -n1 /etc/gpa/.version)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    CHECK_URL="https://api.github.com/repos/snail007/proxy_admin_free/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}ProxyAdmin ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    curl "${CURL_DOWNLOAD_OPTS[@]}" "https://raw.githubusercontent.com/snail007/proxy_admin_free/master/install_auto.sh" | sudo bash && \
        echo "${REMOTE_VERSION}" | sudo tee "/etc/gpa/.version" >/dev/null
fi

cd "${CURRENT_DIR}" || exit