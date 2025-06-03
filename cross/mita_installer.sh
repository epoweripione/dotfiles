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

[[ -z "${OS_PACKAGE_MANAGER}" ]] && get_os_package_manager

# [mieru](https://github.com/enfein/mieru)
INSTALLER_APP_NAME="mita"
INSTALLER_GITHUB_REPO="enfein/mieru"

INSTALLER_IS_INSTALL="no"
INSTALLER_IS_UPDATE="no"

[[ "${OS_PACKAGE_MANAGER}" == "dpkg" || "${OS_PACKAGE_MANAGER}" == "dnf" ]] && INSTALLER_IS_INSTALL="yes"

if [[ -x "$(command -v mita)" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(mita version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    if [[ "${OS_PACKAGE_MANAGER}" == "dpkg" ]]; then
        case "${OS_INFO_ARCH}" in
            amd64)
                INSTALLER_FILE_NAME="mita_${INSTALLER_VER_REMOTE}_${OS_INFO_ARCH}.deb"
                ;;
            arm64)
                INSTALLER_FILE_NAME="mita_${INSTALLER_VER_REMOTE}_${OS_INFO_ARCH}.deb"
                ;;
        esac
    elif [[ "${OS_PACKAGE_MANAGER}" == "dnf" ]]; then
        case "${OS_INFO_ARCH}" in
            amd64)
                INSTALLER_FILE_NAME="mita-${INSTALLER_VER_REMOTE}-1.x86_64.rpm"
                ;;
            arm64)
                INSTALLER_FILE_NAME="mita-${INSTALLER_VER_REMOTE}-1.aarch64.rpm"
                ;;
        esac
    fi

    if [[ -n "${INSTALLER_FILE_NAME}" ]]; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

        INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${INSTALLER_GITHUB_REPO}/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"

        INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_FILE_NAME}"
        if App_Installer_Download_Extract "${INSTALLER_DOWNLOAD_URL}" "${INSTALLER_DOWNLOAD_FILE}" "${WORKDIR}"; then
            if [[ "${OS_PACKAGE_MANAGER}" == "dpkg" ]]; then
                sudo dpkg -i "${INSTALLER_DOWNLOAD_FILE}"
            elif [[ "${OS_PACKAGE_MANAGER}" == "dnf" ]]; then
                sudo rpm -Uvh --force "${INSTALLER_DOWNLOAD_FILE}"
            fi

            # Save downloaded file to cache
            App_Installer_Save_to_Cache "${INSTALLER_APP_NAME}" "${INSTALLER_VER_REMOTE}" "${INSTALLER_DOWNLOAD_FILE}"
        fi
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    # Grant permissions
    if [[ $UID -ne 0 ]]; then
        if ! id -nG "$USER" | grep -qw "mita"; then
            sudo usermod -a -G mita "$USER"

            # echo -n "Reboot now?[y/N]:"
            # read -r IS_REBOOT
            # [[ -z "${IS_REBOOT}" ]] && IS_REBOOT="N"
            # [[ "${IS_REBOOT}" == "y" || "${IS_REBOOT}" == "Y" ]] && sudo reboot
        fi
    fi

    # restart
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

firewall-cmd --permanent --zone=public --add-port=<port>/tcp
firewall-cmd --reload
firewall-cmd --list-all

mita start
mita status
mita stop

sudo journalctl -u mita -xe --no-pager
'
