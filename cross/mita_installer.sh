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

[[ -z "${OS_PACKAGE_MANAGER}" ]] && get_os_package_manager

# [mieru](https://github.com/enfein/mieru)
APP_INSTALL_NAME="mieru"
GITHUB_REPO_NAME="enfein/mieru"

IS_INSTALL="no"
IS_UPDATE="no"

[[ "${OS_PACKAGE_MANAGER}" == "dpkg" || "${OS_PACKAGE_MANAGER}" == "dnf" ]] && IS_INSTALL="yes"

if [[ -x "$(command -v mita)" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(mita version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    App_Installer_Get_Remote_Version "${CHECK_URL}"
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    DOWNLOAD_FILENAME=""
    REMOTE_FILENAME=""
    if [[ "${OS_PACKAGE_MANAGER}" == "dpkg" ]]; then
        DOWNLOAD_FILENAME="${WORKDIR}/mita.deb"
        case "${OS_INFO_ARCH}" in
            amd64)
                REMOTE_FILENAME="mita_${REMOTE_VERSION}_${OS_INFO_ARCH}.deb"
                ;;
            arm64)
                REMOTE_FILENAME="mita_${REMOTE_VERSION}_${OS_INFO_ARCH}.deb"
                ;;
        esac
    elif [[ "${OS_PACKAGE_MANAGER}" == "dnf" ]]; then
        DOWNLOAD_FILENAME="${WORKDIR}/mita.rpm"
        case "${OS_INFO_ARCH}" in
            amd64)
                REMOTE_FILENAME="mita-${REMOTE_VERSION}-1.x86_64.rpm"
                ;;
            arm64)
                REMOTE_FILENAME="mita-${REMOTE_VERSION}-1.aarch64.rpm"
                ;;
        esac
    fi

    curl_download_status=1
    if [[ -n "${REMOTE_FILENAME}" ]]; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
        DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${GITHUB_REPO_NAME}/releases/download/v${REMOTE_VERSION}/${REMOTE_FILENAME}"
        colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"

        curl_download_status=$?
        if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
            DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
            colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
            axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
            curl_download_status=$?
        fi
    fi

    if [[ ${curl_download_status} -eq 0 ]]; then
        if [[ "${OS_PACKAGE_MANAGER}" == "dpkg" ]]; then
            sudo dpkg -i "${DOWNLOAD_FILENAME}"
        elif [[ "${OS_PACKAGE_MANAGER}" == "dnf" ]]; then
            sudo rpm -Uvh --force "${DOWNLOAD_FILENAME}"
        fi
    fi
fi

# Grant permissions
if [[ $UID -ne 0 ]]; then
    if ! id -nG "$USER" | grep -qw "mita"; then
        sudo usermod -a -G mita "$USER"

        echo -n "Reboot now?[Y/n]:"
        read -r IS_REBOOT
        [[ -z "${IS_REBOOT}" ]] && IS_REBOOT="Y"
        [[ "${IS_REBOOT}" == "y" || "${IS_REBOOT}" == "Y" ]] && sudo reboot
    fi
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    if mita status | grep -q 'RUNNING'; then
        sudo systemctl restart mita.service
        # mita stop && mita start
    fi
fi

: '
systemctl status mita
mita status

tee "$HOME/.config/mieru_server.json" >/dev/null <<-'EOF'
{
    "portBindings": [
        {
            "port": -1,
            "protocol": "TCP"
        }
    ],
    "users": [
        {
            "name": "<username@example.com>",
            "password": "<your-password>"
        }
    ],
    "loggingLevel": "INFO",
    "mtu": 1400
}
EOF

mita apply config "$HOME/.config/mieru_server.json"
mita describe config

mita start
mita status
mita stop

sudo journalctl -u mita -xe --no-pager
'
