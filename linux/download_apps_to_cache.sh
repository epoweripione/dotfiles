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

if [[ $# -lt 2 ]]; then
    echo "Usage: $(basename "$0") download-to-directory app-list-file [all,dryrun]"
    echo "eg: $(basename "$0") \$HOME/AppCache applist.txt all,dryrun"
    echo 'Genrate app list:'
    echo '  grep -hr -E "INSTALLER_GITHUB_REPO=\"[^\{]+\"" "$HOME/.dotfiles" --include="*.sh" --exclude-dir="node_modules" | cut -d\" -f2 | sort -u > $HOME/apps.txt'
    exit 1
fi

CACHE_DIR=$1
[[ ! -d "${CACHE_DIR}" ]] && mkdir -p "${CACHE_DIR}"

APP_LIST_FILE=$2
[[ ! -f "${APP_LIST_FILE}" ]] && {
    colorEcho "${RED}App list file not found: ${FUCHSIA}${APP_LIST_FILE}"
    exit 1
}

DOWNLOAD_OPTIONS="$3"

## app list file format: app_name or github_repo#check_url#archive_file_extension#filename_match_pattern#version_match_pattern
# eza-community/eza
# ncdu#https://dev.yorhel.nl/ncdu#tar.gz#/download/ncdu-[^<>:;,?"*|/]+\.tar\.gz#ncdu-.*\.tar\.gz

APP_JSON_FILE="${CACHE_DIR}/apps.json"
[[ ! -f "${APP_JSON_FILE}" ]] && echo -e '[]' | tee "${APP_JSON_FILE}" >/dev/null

APP_JSON="$(cat "${APP_JSON_FILE}")"

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

while read -r line; do
    # Skip empty lines and comments
    [[ -z "${line}" || "${line}" =~ ^# ]] && continue

    App_Installer_Reset

    if grep -q '#' <<<"${line}"; then
        APP_NAME=$(awk -F"#" '{print $1}' <<< "${line}")
        INSTALLER_CHECK_URL=$(awk -F"#" '{print $2}' <<< "${line}")
        INSTALLER_ARCHIVE_EXT=$(awk -F'#' '{print $3}' <<<"${line}")
        FILENAME_PATTERN=$(awk -F"#" '{print $4}' <<< "${line}")
        VERSION_PATTERN=$(awk -F"#" '{print $5}' <<< "${line}")
    else
        INSTALLER_CHECK_URL="${line}"
        APP_NAME=$(awk -F"/" '{print $NF}' <<< "${line}")
        FILENAME_PATTERN="jq=.assets[].browser_download_url"
        VERSION_PATTERN="jq=.tag_name"
    fi

    if [[ "${INSTALLER_CHECK_URL}" =~ ^(https?://|ftp://) ]]; then
        INSTALLER_GITHUB_REPO=""
    else
        INSTALLER_GITHUB_REPO="${INSTALLER_CHECK_URL}"
        INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    fi

    # Get app latest version
    if [[ -n "${VERSION_PATTERN}" ]]; then
        colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_NAME}${BLUE}..."
        App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}" "${VERSION_PATTERN}"
    fi

    # Get app download URLs
    App_Installer_Get_Remote_URL "${INSTALLER_CHECK_URL}" "${FILENAME_PATTERN}" "${VERSION_PATTERN}"

    [[ -z "${INSTALLER_VER_REMOTE}" ]] && continue
    [[ -z "${INSTALLER_ALL_DOWNLOAD_URLS}" ]] && continue

    # Add app to json
    JSON_APP_NAME=$(jq -r ".[] | select(.name == \"${APP_NAME}\").name//empty" <<< "${APP_JSON}")
    if [[ -z "${JSON_APP_NAME}" ]]; then
        APP_JSON=$(jq -r ". += [{\"name\": \"${APP_NAME}\"}]" <<< "${APP_JSON}")
    fi

    # App info
    APP_JSON=$(jq -r "(.[] | select(.name == \"${APP_NAME}\")).source |= \"${INSTALLER_CHECK_URL}\"" <<< "${APP_JSON}")
    APP_JSON=$(jq -r "(.[] | select(.name == \"${APP_NAME}\")).repository |= \"${INSTALLER_GITHUB_REPO}\"" <<< "${APP_JSON}")

    JSON_APP_OPTIONS=$(sed 's/[\\\"]/\\&/g' <<<"${line}")
    APP_JSON=$(jq -r "(.[] | select(.name == \"${APP_NAME}\")).options |= \"${JSON_APP_OPTIONS}\"" <<< "${APP_JSON}")

    ## Check app version and URLs
    # JSON_APP_VERSION=$(jq -r ".[] | select(.name == \"${APP_NAME}\").version//empty" <<< "${APP_JSON}")
    # [[ -z "${JSON_APP_VERSION}" ]] && JSON_APP_VERSION="0.0.0"
    # JSON_APP_URLS=$(jq -r ".[] | select(.name == \"${APP_NAME}\").urls//empty" <<< "${APP_JSON}")
    # if version_le "${INSTALLER_VER_REMOTE}" "${JSON_APP_VERSION}"; then
    #     [[ -n "${JSON_APP_URLS}" ]] && continue
    # fi

    # App version
    APP_JSON=$(jq -r "(.[] | select(.name == \"${APP_NAME}\")).version |= \"${INSTALLER_VER_REMOTE}\"" <<< "${APP_JSON}")

    # App download URLs
    INSTALLER_ALL_DOWNLOAD_URLS=$(sort -u <<<"${INSTALLER_ALL_DOWNLOAD_URLS}")
    if grep -q "^/" <<<"${INSTALLER_ALL_DOWNLOAD_URLS}"; then
        URL_PROTOCOL=$(awk -F/ '{print $1}' <<<"${INSTALLER_CHECK_URL}")
        URL_DOMAIN=$(awk -F/ '{print $3}' <<<"${INSTALLER_CHECK_URL}")
        INSTALLER_ALL_DOWNLOAD_URLS=$(sed "s|^|${URL_PROTOCOL}//${URL_DOMAIN}|" <<<"${INSTALLER_ALL_DOWNLOAD_URLS}")
    fi

    APP_JSON=$(jq -r "(.[] | select(.name == \"${APP_NAME}\")).urls |= []" <<< "${APP_JSON}")
    while read -r downloadUrl; do
        [[ -z "${downloadUrl}" ]] && continue
        APP_JSON=$(jq -r "(.[] | select(.name == \"${APP_NAME}\")).urls += [\"${downloadUrl}\"]" <<< "${APP_JSON}")
    done <<<"${INSTALLER_ALL_DOWNLOAD_URLS}"

    # Download app
    if [[ -n "${INSTALLER_ALL_DOWNLOAD_URLS}" ]]; then
        colorEcho "${BLUE}Downloading ${FUCHSIA}${APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    fi

    if ! grep -q -i 'all' <<< "${DOWNLOAD_OPTIONS}"; then
        # Only download file that match running platform by default
        INSTALLER_ALL_DOWNLOAD_URLS="${INSTALLER_DOWNLOAD_URL}"
    fi

    while read -r downloadUrl; do
        [[ -z "${downloadUrl}" ]] && continue

        if grep -q -i 'dryrun' <<< "${DOWNLOAD_OPTIONS}"; then
            colorEcho "${BLUE}  From ${ORANGE}${downloadUrl}"
            continue
        fi

        DOWNLOAD_FILENAME=$(basename "${downloadUrl}" | cut -d'?' -f1)
        [[ -f "${CACHE_DIR}/${DOWNLOAD_FILENAME}" ]] && continue

        App_Installer_Download "${downloadUrl}" "${CACHE_DIR}/${DOWNLOAD_FILENAME}"
    done <<<"${INSTALLER_ALL_DOWNLOAD_URLS}"
done < "${APP_LIST_FILE}"

echo "${APP_JSON}" > "${APP_JSON_FILE}"

# colorEcho "${GREEN}All apps in ${FUCHSIA}${APP_LIST_FILE}${GREEN} have been downloaded to ${YELLOW}${CACHE_DIR}"

cd "${CURRENT_DIR}" || exit
