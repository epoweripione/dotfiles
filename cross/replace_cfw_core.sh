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
        echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh not exist!"
        exit 0
    fi
fi

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# WSL
WSL_USERPROFILE=""
if check_os_wsl; then
    WSL_USERPROFILE=$(wslpath "$(wslvar USERPROFILE 2>/dev/null)")
fi

# Replace `clash` with `clash-meta`
App_Installer_Reset

[[ -z "${OS_INFO_MATCH_TYPE}" ]] && App_Installer_Get_OS_Info_Match_Cond

CFW_CLASH_BIN="${WSL_USERPROFILE}/scoop/apps/clash-for-windows/current/resources/static/files/win/x64/clash-win64.exe"
if [[ -n "${WSL_USERPROFILE}" && -s "${CFW_CLASH_BIN}" ]]; then
    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/clash-windows.zip"
    INSTALLER_ARCHIVE_EXEC_NAME="Clash.Meta-windows-amd64.exe"

    INSTALLER_DOWNLOAD_URL=$(curl "${CURL_CHECK_OPTS[@]}" https://api.github.com/repos/MetaCubeX/Clash.Meta/releases \
        | jq -r 'map(select(.prerelease)) | first | .assets[].browser_download_url')

    MATCH_URL=$(grep -Ei "windows" <<<"${INSTALLER_DOWNLOAD_URL}" | grep -Ei "${OS_INFO_MATCH_ARCH}" | grep -Ei "${OS_INFO_MATCH_CPU_LEVEL}")
    if [[ -z "${MATCH_URL}" ]]; then
        INSTALLER_DOWNLOAD_URL=$(grep -Ei "windows" <<<"${INSTALLER_DOWNLOAD_URL}" | grep -Ei "${OS_INFO_MATCH_ARCH}")
    else
        INSTALLER_DOWNLOAD_URL="${MATCH_URL}"
    fi

    INSTALLER_DOWNLOAD_URL=$(head -n1 <<<"${INSTALLER_DOWNLOAD_URL}")
    if [[ -n "${INSTALLER_DOWNLOAD_URL}" ]]; then
        colorEcho "${BLUE}Downloading ${FUCHSIA}${INSTALLER_DOWNLOAD_URL}${BLUE} to ${ORANGE}${CFW_CLASH_BIN}${BLUE}..."
        if App_Installer_Download_Extract "${INSTALLER_DOWNLOAD_URL}" "${INSTALLER_DOWNLOAD_FILE}" "${WORKDIR}"; then
            [[ -L "${CFW_CLASH_BIN}" ]] && sudo rm -f "${CFW_CLASH_BIN}"
            [[ ! -s "${CFW_CLASH_BIN}.orig" ]] && sudo mv -f "${CFW_CLASH_BIN}" "${CFW_CLASH_BIN}.orig"
            [[ -s "${WORKDIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && sudo cp -f "${WORKDIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" "${CFW_CLASH_BIN}"
        fi
    fi
fi

CFW_CLASH_BIN="/opt/clash-for-windows-bin/resources/static/files/linux/x64/clash-linux"
[[ ! -s "${CFW_CLASH_BIN}" ]] && CFW_CLASH_BIN="/opt/clash-for-windows/static/files/linux/x64/clash-linux"
if [[ -s "${CFW_CLASH_BIN}" ]]; then
    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/clash-linux.gz"
    INSTALLER_ARCHIVE_EXEC_NAME="clash-linux"

    INSTALLER_DOWNLOAD_URL=$(curl "${CURL_CHECK_OPTS[@]}" https://api.github.com/repos/MetaCubeX/Clash.Meta/releases \
        | jq -r 'map(select(.prerelease)) | first | .assets[].browser_download_url')

    MATCH_URL=$(grep -Ei "${OS_INFO_MATCH_TYPE}" <<<"${INSTALLER_DOWNLOAD_URL}" | grep -Ei "${OS_INFO_MATCH_ARCH}" | grep -Ei "${OS_INFO_MATCH_CPU_LEVEL}")
    if [[ -z "${MATCH_URL}" ]]; then
        INSTALLER_DOWNLOAD_URL=$(grep -Ei "${OS_INFO_MATCH_TYPE}" <<<"${INSTALLER_DOWNLOAD_URL}" | grep -Ei "${OS_INFO_MATCH_ARCH}")
    else
        INSTALLER_DOWNLOAD_URL="${MATCH_URL}"
    fi

    INSTALLER_DOWNLOAD_URL=$(head -n1 <<<"${INSTALLER_DOWNLOAD_URL}")
    if [[ -n "${INSTALLER_DOWNLOAD_URL}" ]]; then
        colorEcho "${BLUE}Downloading ${FUCHSIA}${INSTALLER_DOWNLOAD_URL}${BLUE} to ${ORANGE}${CFW_CLASH_BIN}${BLUE}..."
        if App_Installer_Download_Extract "${INSTALLER_DOWNLOAD_URL}" "${INSTALLER_DOWNLOAD_FILE}" "${WORKDIR}"; then
            [[ -L "${CFW_CLASH_BIN}" ]] && sudo rm -f "${CFW_CLASH_BIN}"
            [[ ! -s "${CFW_CLASH_BIN}.orig" ]] && sudo mv -f "${CFW_CLASH_BIN}" "${CFW_CLASH_BIN}.orig"
            [[ -s "${WORKDIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" ]] && sudo cp -f "${WORKDIR}/${INSTALLER_ARCHIVE_EXEC_NAME}" "${CFW_CLASH_BIN}"
            sudo chmod +x "${CFW_CLASH_BIN}"
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit