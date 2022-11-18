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

RSYNC_REMOTE="$1" # root@10.0.0.2:/srv/web/www/public

OS_INFO_WSL=$(uname -r)

# WSL1 & WSL2
WSL_USERPROFILE=""
if [[ "${OS_INFO_WSL}" =~ "Microsoft" || "${OS_INFO_WSL}" =~ "microsoft" ]]; then
    WSL_USERPROFILE=$(wslpath "$(wslvar USERPROFILE)")
fi


# clash-for-windows
PROFILE=""
if [[ -s "$HOME/.config/clash/profiles/list.yml" ]]; then
    PROFILE="$HOME/.config/clash/profiles/list.yml"
    PROFILE_DIR="$HOME/.config/clash/profiles"
fi

if [[ -z "${PROFILE}" && -n "${WSL_USERPROFILE}" ]]; then
    if [[ -s "${WSL_USERPROFILE}/.config/clash/profiles/list.yml" ]]; then
        PROFILE="${WSL_USERPROFILE}/.config/clash/profiles/list.yml"
        PROFILE_DIR="${WSL_USERPROFILE}/.config/clash/profiles"
    fi

    if [[ -s "${WSL_USERPROFILE}/scoop/persist/clash-for-windows/data/profiles/list.yml" ]]; then
        PROFILE="${WSL_USERPROFILE}/scoop/persist/clash-for-windows/data/profiles/list.yml"
        PROFILE_DIR="${WSL_USERPROFILE}/scoop/persist/clash-for-windows/data/profiles"
    fi
fi

if [[ -s "${PROFILE}" ]]; then
    PROFILE_LEN=$(yq '.files | length' "${PROFILE}")
    for ((i=0; i < PROFILE_LEN; ++i)); do
        PROFILE_FILE=$(yq ".files[$i].time" "${PROFILE}")
        DOWNLOAD_URL=$(yq ".files[$i].url" "${PROFILE}")

        DOWNLOAD_FILENAME="${WORKDIR}/${PROFILE_FILE}"

        if [[ -z "${RSYNC_REMOTE}" ]]; then
            colorEcho "${BLUE}Downloading ${FUCHSIA}${DOWNLOAD_URL}${BLUE} to ${ORANGE}${PROFILE_DIR}/${PROFILE_FILE}${BLUE}..."
            axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        else
            REMOTE_FILENAME=$(echo "${DOWNLOAD_URL}" | awk -F'/' '{print $NF}' | cut -d'?' -f1)
            colorEcho "${BLUE}Downloading ${FUCHSIA}${RSYNC_REMOTE}/${REMOTE_FILENAME}${BLUE} to ${ORANGE}${PROFILE_DIR}/${PROFILE_FILE}${BLUE}..."
            rsync -avz --progress "${RSYNC_REMOTE}/${REMOTE_FILENAME}" "${DOWNLOAD_FILENAME}"
        fi

        curl_download_status=$?
        if [[ ${curl_download_status} -eq 0 ]]; then
            cp -f "${DOWNLOAD_FILENAME}" "${PROFILE_DIR}/${PROFILE_FILE}"

            yq -i ".files[$i].selected=[]" "${PROFILE}"
        fi
    done
fi


# clash-verge
PROFILE=""
if [[ -s "$HOME/.config/clash-verge/profiles.yaml" ]]; then
    PROFILE="$HOME/.config/clash-verge/profiles.yaml"
    PROFILE_DIR="$HOME/.config/clash-verge/profiles"
fi

if [[ -z "${PROFILE}" && -n "${WSL_USERPROFILE}" ]]; then
    if [[ -s "${WSL_USERPROFILE}/.config/clash-verge/profiles.yaml" ]]; then
        PROFILE="${WSL_USERPROFILE}/.config/clash-verge/profiles.yaml"
        PROFILE_DIR="${WSL_USERPROFILE}/.config/clash-verge/profiles"
    fi

    if [[ -s "${WSL_USERPROFILE}/scoop/persist/clash-verge/.config/clash-verge/profiles.yaml" ]]; then
        PROFILE="${WSL_USERPROFILE}/scoop/persist/clash-verge/.config/clash-verge/profiles.yaml"
        PROFILE_DIR="${WSL_USERPROFILE}/scoop/persist/clash-verge/.config/clash-verge/profiles"
    fi
fi

if [[ -s "${PROFILE}" ]]; then
    PROFILE_LEN=$(yq '.items | length' "${PROFILE}")
    for ((i=0; i < PROFILE_LEN; ++i)); do
        PROFILE_FILE=$(yq ".items[$i].file" "${PROFILE}")
        DOWNLOAD_URL=$(yq ".items[$i].url" "${PROFILE}")

        DOWNLOAD_FILENAME="${WORKDIR}/${PROFILE_FILE}"

        if [[ -z "${RSYNC_REMOTE}" ]]; then
            colorEcho "${BLUE}Downloading ${FUCHSIA}${DOWNLOAD_URL}${BLUE} to ${ORANGE}${PROFILE_DIR}/${PROFILE_FILE}${BLUE}..."
            axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        else
            REMOTE_FILENAME=$(echo "${DOWNLOAD_URL}" | awk -F'/' '{print $NF}' | cut -d'?' -f1)
            colorEcho "${BLUE}Downloading ${FUCHSIA}${RSYNC_REMOTE}/${REMOTE_FILENAME}${BLUE} to ${ORANGE}${PROFILE_DIR}/${PROFILE_FILE}${BLUE}..."
            rsync -avz --progress "${RSYNC_REMOTE}/${REMOTE_FILENAME}" "${DOWNLOAD_FILENAME}"
        fi

        curl_download_status=$?
        if [[ ${curl_download_status} -eq 0 ]]; then
            cp -f "${DOWNLOAD_FILENAME}" "${PROFILE_DIR}/${PROFILE_FILE}"

            PROFILE_UPDATED=$(date +"%s")
            yq -i ".items[$i].updated=${PROFILE_UPDATED}" "${PROFILE}"
            yq -i ".items[$i].selected=[]" "${PROFILE}"
        fi
    done
fi

# Replace `clash` with `clash-meta`
App_Installer_Reset

[[ -z "${OS_INFO_MATCH_TYPE}" ]] && App_Installer_Get_OS_Info_Match_Cond

CFW_CLASH_BIN="${WSL_USERPROFILE}/scoop/apps/clash-for-windows/current/resources/static/files/win/x64/clash-win64.exe"
if [[ -n "${WSL_USERPROFILE}" && -s "${CFW_CLASH_BIN}" ]]; then
    DOWNLOAD_FILENAME="${WORKDIR}/clash-windows.zip"
    ARCHIVE_EXEC_NAME="Clash.Meta-windows-amd64.exe"

    REMOTE_DOWNLOAD_URL=$(curl "${CURL_CHECK_OPTS[@]}" https://api.github.com/repos/MetaCubeX/Clash.Meta/releases \
        | jq -r 'map(select(.prerelease)) | first | .assets[].browser_download_url')

    MATCH_URL=$(grep -Ei "windows" <<<"${REMOTE_DOWNLOAD_URL}" | grep -Ei "${OS_INFO_MATCH_ARCH}" | grep -Ei "${OS_INFO_MATCH_CPU_LEVEL}")
    if [[ -z "${MATCH_URL}" ]]; then
        REMOTE_DOWNLOAD_URL=$(grep -Ei "windows" <<<"${REMOTE_DOWNLOAD_URL}" | grep -Ei "${OS_INFO_MATCH_ARCH}")
    else
        REMOTE_DOWNLOAD_URL="${MATCH_URL}"
    fi

    REMOTE_DOWNLOAD_URL=$(head -n1 <<<"${REMOTE_DOWNLOAD_URL}")
    if [[ -n "${REMOTE_DOWNLOAD_URL}" ]]; then
        colorEcho "${BLUE}Downloading ${FUCHSIA}${REMOTE_DOWNLOAD_URL}${BLUE} to ${ORANGE}${CFW_CLASH_BIN}${BLUE}..."
        if App_Installer_Download_Extract "${REMOTE_DOWNLOAD_URL}" "${DOWNLOAD_FILENAME}" "${WORKDIR}"; then
            [[ -L "${CFW_CLASH_BIN}" ]] && sudo rm -f "${CFW_CLASH_BIN}"
            [[ ! -s "${CFW_CLASH_BIN}.orig" ]] && sudo mv -f "${CFW_CLASH_BIN}" "${CFW_CLASH_BIN}.orig"
            [[ -s "${WORKDIR}/${ARCHIVE_EXEC_NAME}" ]] && sudo cp -f "${WORKDIR}/${ARCHIVE_EXEC_NAME}" "${CFW_CLASH_BIN}"
        fi
    fi
fi

CFW_CLASH_BIN="/opt/clash-for-windows-bin/resources/static/files/linux/x64/clash-linux"
if [[ -s "${CFW_CLASH_BIN}" ]]; then
    DOWNLOAD_FILENAME="${WORKDIR}/clash-linux.gz"
    ARCHIVE_EXEC_NAME="clash-linux"

    REMOTE_DOWNLOAD_URL=$(curl "${CURL_CHECK_OPTS[@]}" https://api.github.com/repos/MetaCubeX/Clash.Meta/releases \
        | jq -r 'map(select(.prerelease)) | first | .assets[].browser_download_url')

    MATCH_URL=$(grep -Ei "${OS_INFO_MATCH_TYPE}" <<<"${REMOTE_DOWNLOAD_URL}" | grep -Ei "${OS_INFO_MATCH_ARCH}" | grep -Ei "${OS_INFO_MATCH_CPU_LEVEL}")
    if [[ -z "${MATCH_URL}" ]]; then
        REMOTE_DOWNLOAD_URL=$(grep -Ei "${OS_INFO_MATCH_TYPE}" <<<"${REMOTE_DOWNLOAD_URL}" | grep -Ei "${OS_INFO_MATCH_ARCH}")
    else
        REMOTE_DOWNLOAD_URL="${MATCH_URL}"
    fi

    REMOTE_DOWNLOAD_URL=$(head -n1 <<<"${REMOTE_DOWNLOAD_URL}")
    if [[ -n "${REMOTE_DOWNLOAD_URL}" ]]; then
        colorEcho "${BLUE}Downloading ${FUCHSIA}${REMOTE_DOWNLOAD_URL}${BLUE} to ${ORANGE}${CFW_CLASH_BIN}${BLUE}..."
        if App_Installer_Download_Extract "${REMOTE_DOWNLOAD_URL}" "${DOWNLOAD_FILENAME}" "${WORKDIR}"; then
            [[ -L "${CFW_CLASH_BIN}" ]] && sudo rm -f "${CFW_CLASH_BIN}"
            [[ ! -s "${CFW_CLASH_BIN}.orig" ]] && sudo mv -f "${CFW_CLASH_BIN}" "${CFW_CLASH_BIN}.orig"
            [[ -s "${WORKDIR}/${ARCHIVE_EXEC_NAME}" ]] && sudo cp -f "${WORKDIR}/${ARCHIVE_EXEC_NAME}" "${CFW_CLASH_BIN}"
            sudo chmod +x "${CFW_CLASH_BIN}"
        fi
    fi
fi


cd "${CURRENT_DIR}" || exit