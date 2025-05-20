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

# trojan
# https://github.com/trojan-gfw/trojan
INSTALLER_APP_NAME="trojan"

if [[ -s "/srv/trojan/trojan" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(/srv/trojan/trojan --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/trojan-gfw/trojan/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    systemctl is-enabled trojan >/dev/null 2>&1 && sudo systemctl stop trojan

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/trojan.tar.xz"
    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/trojan-gfw/trojan/releases/download/v${INSTALLER_VER_REMOTE}/trojan-${INSTALLER_VER_REMOTE}-${OS_INFO_TYPE}-${OS_INFO_ARCH}.tar.xz"
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
        sudo tar -xJf "${INSTALLER_DOWNLOAD_FILE}" -C "/srv"
    fi

    if [[ ! -s "/etc/systemd/system/trojan.service" ]]; then
        [[ "${INSTALLER_IS_UPDATE}" == "no" ]] && \
                colorEchoN "${ORANGE}Install trojan systemd service?[y/${CYAN}N${ORANGE}]: " && \
                read -r CHOICE
        if [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]]; then
            sudo cp -f /srv/trojan/examples/trojan.service-example /etc/systemd/system/trojan.service
            sudo sed -i "s|ExecStart=.*|ExecStart=/srv/trojan/trojan -c /etc/trojan/trojan.json|" /etc/systemd/system/trojan.service
        fi
    fi

    if [[ ! -s "/etc/trojan/trojan.json" ]]; then
        sudo mkdir -p "/etc/trojan" && \
            sudo cp -f "/srv/trojan/examples/server.json-example" "/etc/trojan/trojan.json"
    fi

    # nohup /srv/trojan/trojan -c /etc/trojan/trojan.json >/dev/null 2>&1 & disown
    systemctl is-enabled trojan >/dev/null 2>&1 || sudo systemctl enable trojan
    systemctl is-enabled trojan >/dev/null 2>&1 && sudo systemctl restart trojan
fi

cd "${CURRENT_DIR}" || exit