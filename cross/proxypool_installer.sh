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

# proxypool
# https://github.com/Sansui233/proxypool
INSTALLER_APP_NAME="proxypool"
INSTALLER_GITHUB_REPO="Sansui233/proxypool"

INSTALLER_INSTALL_NAME="proxypool"

INSTALLER_ARCHIVE_EXT="gz"
INSTALLER_ARCHIVE_EXEC_NAME="proxypool"

INSTALLER_VER_FILE="${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}.version"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    [[ -s "${INSTALLER_VER_FILE}" ]] && INSTALLER_VER_CURRENT=$(head -n1 "${INSTALLER_VER_FILE}")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi

# config
if [[ ! -s "/etc/proxypool/config.yaml" && -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    mkdir -p "/etc/proxypool" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/source.yaml" \
            "https://raw.githubusercontent.com/Sansui233/proxypool/master/config/source.yaml" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/config.yaml" \
            "https://raw.githubusercontent.com/Sansui233/proxypool/master/config/config.yaml" && \
        sudo cp -f "${WORKDIR}/source.yaml" "/etc/proxypool/source.yaml" && \
        sudo cp -f "${WORKDIR}/config.yaml" "/etc/proxypool/config.yaml" && \
        sudo sed -i "s|./config/source.yaml|/etc/proxypool/source.yaml|" "/etc/proxypool/config.yaml"
fi

# sudo sed -i "s|domain:.*|domain: pool.example.com|" "/etc/proxypool/config.yaml"
# Install_systemd_Service "proxypool" "/usr/local/bin/proxypool -c /etc/proxypool/config.yaml"

## nginx
# proxy_pass http://127.0.0.1:12580/;


cd "${CURRENT_DIR}" || exit