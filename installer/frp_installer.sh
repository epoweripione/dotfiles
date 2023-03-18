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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch

# frp
# https://github.com/fatedier/frp
INSTALLER_APP_NAME="frp"

if [[ -d "/srv/frp" ]]; then
    INSTALLER_VER_CURRENT=$(/srv/frp/frps --version 2>&1)
    # backup ini files
    sudo mkdir -p "/srv/backup_frp" && \
        sudo cp -f /srv/frp/*.ini "/srv/backup_frp" && \
        sudo rm -f "/srv/backup_frp/frpc_full.ini" && \
        sudo rm -f "/srv/backup_frp/frps_full.ini"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/fatedier/frp/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    if pgrep -f "frps" >/dev/null 2>&1; then
        sudo pkill -f "frps"
    fi

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/frp.tar.gz"
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/fatedier/frp/releases/download/v${INSTALLER_VER_REMOTE}/frp_${INSTALLER_VER_REMOTE}_${OS_INFO_TYPE}_${OS_INFO_ARCH}.tar.gz"
    colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
    axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
        INSTALLER_DOWNLOAD_URL="${INSTALLER_DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
        colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"
        curl_download_status=$?
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        tar -xzf "${INSTALLER_DOWNLOAD_FILE}" -C "${WORKDIR}" && \
            sudo mkdir -p "/srv/frp" && \
            sudo cp -rf "${WORKDIR}"/frp_*/* "/srv/frp"
    fi

    [[ -d "/srv/backup_frp" ]] && sudo cp -f /srv/backup_frp/*.ini "/srv/frp"

    # if [[ -s "/srv/frp/frps.ini" ]]; then
    #     nohup /srv/frp/frps -c /srv/frp/frps.ini >/dev/null 2>&1 & disown
    # fi

    # systemctl is-enabled frp-server >/dev/null 2>&1 || {
    #         Install_systemd_Service "frp-server" "/srv/frp/frps -c /srv/frp/frps-server.ini"
    #     }

    systemctl is-enabled frp-server >/dev/null 2>&1 && sudo systemctl restart frp-server
fi


# sed -i '/^exit 0/i\nohup /srv/frp/frps -c /srv/frp/frps.ini >/dev/null 2>&1 & disown\n' /etc/rc.local
