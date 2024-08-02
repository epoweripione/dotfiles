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

# WSL
WSL_USERPROFILE=""
if check_os_wsl; then
    WSL_USERPROFILE=$(wslpath "$(wslvar USERPROFILE 2>/dev/null)")
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
            rsync -avzP "${RSYNC_REMOTE}/${REMOTE_FILENAME}" "${DOWNLOAD_FILENAME}"
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


# clash-verge-rev
PROFILE=""
if [[ -s "$HOME/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles.yaml" ]]; then
    PROFILE="$HOME/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles.yaml"
    PROFILE_DIR="$HOME/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles"
fi

if [[ -z "${PROFILE}" && -n "${WSL_USERPROFILE}" ]]; then
    if [[ -s "${WSL_USERPROFILE}/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles.yaml" ]]; then
        PROFILE="${WSL_USERPROFILE}/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles.yaml"
        PROFILE_DIR="${WSL_USERPROFILE}/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles"
    fi

    if [[ -s "${WSL_USERPROFILE}/scoop/persist/clash-verge/.config/io.github.clash-verge-rev.clash-verge-rev/profiles.yaml" ]]; then
        PROFILE="${WSL_USERPROFILE}/scoop/persist/clash-verge/.config/io.github.clash-verge-rev.clash-verge-rev/profiles.yaml"
        PROFILE_DIR="${WSL_USERPROFILE}/scoop/persist/clash-verge/.config/io.github.clash-verge-rev.clash-verge-rev/profiles"
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
            rsync -avzP "${RSYNC_REMOTE}/${REMOTE_FILENAME}" "${DOWNLOAD_FILENAME}"
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


cd "${CURRENT_DIR}" || exit