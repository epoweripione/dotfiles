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

# [LXGW XiHei/霞鶩晰黑/LXGW 晰ゴシック](https://github.com/lxgw/LxgwXiHei)
INSTALLER_APP_NAME="LXGW XiHei/霞鶩晰黑/LXGW 晰ゴシック"
INSTALLER_GITHUB_REPO="lxgw/LxgwXiHei"
INSTALLER_INSTALL_NAME="LxgwXiHei"

INSTALLER_MATCH_PATTERN="LXGWXiHei*"

INSTALLER_INSTALL_PATH="/usr/share/fonts/${INSTALLER_INSTALL_NAME}"
INSTALLER_VER_FILE="${INSTALLER_INSTALL_PATH}/${INSTALLER_INSTALL_NAME}.version"

if [[ -d "${INSTALLER_INSTALL_PATH}" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(sudo head -n1 "${INSTALLER_VER_FILE}" 2>/dev/null)
    [[ -z "${INSTALLER_VER_CURRENT}" ]] && INSTALLER_VER_CURRENT="0.0.0"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" 2>/dev/null \
        | jq -r ".tag_name//empty" 2>/dev/null \
        | grep -Eo -m1 '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

# Install Latest Version
if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    [[ ! -d "${INSTALLER_INSTALL_PATH}" ]] && sudo mkdir -p "${INSTALLER_INSTALL_PATH}"
    # Batch download
    INSTALLER_DOWNLOAD_URLS=(
        "https://github.com/${INSTALLER_GITHUB_REPO}/releases/download/v${INSTALLER_VER_REMOTE}/LXGWXiHeiCL.ttf"
        "https://github.com/${INSTALLER_GITHUB_REPO}/releases/download/v${INSTALLER_VER_REMOTE}/LXGWXiHeiMN.ttf"
    )
    INSTALLER_DOWNLOAD_COUNT=0
    for download_url in "${INSTALLER_DOWNLOAD_URLS[@]}"; do
        INSTALLER_DOWNLOAD_FILE="$(awk -F"/" '{print $NF}' <<<"${download_url}")"
        if App_Installer_Download_Extract "${download_url}" "${WORKDIR}/${INSTALLER_DOWNLOAD_FILE}" "${WORKDIR}"; then
            INSTALLER_DOWNLOAD_COUNT=$((INSTALLER_DOWNLOAD_COUNT + 1))
        fi
    done
    # Batch install
    if [[ ${INSTALLER_DOWNLOAD_COUNT} -eq ${#INSTALLER_DOWNLOAD_URLS[@]} ]]; then
        # Save downloaded file to cache
        INSTALLER_ALL_DOWNLOAD_URLS=$(IFS=$'\n'; echo "${INSTALLER_DOWNLOAD_URLS[*]}")
        INSTALLER_ADDON_FILES=()
        for download_url in "${INSTALLER_DOWNLOAD_URLS[@]}"; do
            INSTALLER_DOWNLOAD_FILE="$(awk -F"/" '{print $NF}' <<<"${download_url}")"
            INSTALLER_ADDON_FILES+=("${INSTALLER_DOWNLOAD_FILE%%[?#]*}")
        done
        App_Installer_Save_to_Cache "${INSTALLER_APP_NAME}" "${INSTALLER_VER_REMOTE}" "${WORKDIR}/${INSTALLER_DOWNLOAD_FILE}"

        # Install fonts
        install_fonts=$(find "${WORKDIR}" -type f -iname "${INSTALLER_MATCH_PATTERN}" -a \( -name "*.ttf" -o -name "*.ttc" \))
        while read -r finded_font; do
            [[ -f "${finded_font}" ]] && sudo mv -f "${finded_font}" "${INSTALLER_INSTALL_PATH}"
        done <<<"${install_fonts}"

        sudo chmod -R 744 "${INSTALLER_INSTALL_PATH}"
        echo "${INSTALLER_VER_REMOTE}" | sudo tee "${INSTALLER_VER_FILE}" >/dev/null

        # update font cache
        colorEcho "${BLUE}  Updating ${FUCHSIA}fontconfig cache${BLUE}..."
        sudo fc-cache -fv >/dev/null 2>&1
    else
        colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
    fi
fi

cd "${CURRENT_DIR}" || exit