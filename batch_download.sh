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

function get_remote_file_size() {
    local REMOTE_FILE_URL=$1

    if [[ -n "$REMOTE_FILE_URL" ]]; then
        curl -fsSL -I "${REMOTE_FILE_URL}" \
            | grep -i "content-length" \
            | cut -d' ' -f2
    else
        echo 0
    fi
}

function get_remote_file_timestamp_modified() {
    local REMOTE_FILE_URL=$1

    if [[ -n "$REMOTE_FILE_URL" ]]; then
        curl -fsSL -I "$REMOTE_FILE_URL" \
            | grep -i "last-modified" \
            | cut -d' ' -f2- \
            | xargs -I{} date -d {} "+%s"
    else
        echo 0
    fi
}

function timestamp2date() {
    date -d @"$1"
}

function get_timestamp() {
    date +"%s"
}

# localfilesize=$(stat -c%s nerd-fonts.zip)
# localfilemodt=$(stat -c%Y nerd-fonts.zip)

# currenttime=$( timestamp )
# remotefilemodt=$( get_remote_file_timestamp_modified https://www.raycloud.tk/nerd-fonts.zip )
# [[ "$currenttime" -ne "$remotefilemodt" ]] && echo "no match"

function get_remote_download_list() {
    local remote_url=$1
    local file_pattern=$2
    local match_pattern=$3
    local filter_pattern=$4
    local remote_content match_urls match_result

    remote_content=$(curl "${CURL_CHECK_OPTS[@]}" "${remote_url}" 2>/dev/null)
    [[ -z "${remote_content}" ]] && colorEcho "${RED}  Error occurred while downloading from ${FUCHSIA}${remote_url}${RED}!" && return 1

    REMOTE_URL_LIST=""

    # extract download urls
    if grep -q -E "^jq=" <<<"${file_pattern}"; then
        # use `jq` if start with `jq=`
        # jq=.assets[].browser_download_url
        # jq=map(select(.prerelease))|first|.assets[].browser_download_url
        match_urls=$(jq -r "${file_pattern/jq=/}" <<<"${remote_content}")
    else
        match_urls=$(grep -E "${file_pattern}" <<<"${remote_content}" \
            | grep -o -P "(((ht|f)tps?):\/\/)+[\w-]+(\.[\w-]+)+([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?")

        if ! grep -q -E "${file_pattern}" <<<"${match_urls}"; then
            match_urls=""
        fi

        [[ -z "${match_urls}" ]] && match_urls=$(grep -Eo "${file_pattern}" <<<"${remote_content}")
    fi

    [[ -n "${match_pattern}" && "${match_pattern}" != "*" ]] && match_urls=$(grep -Ei "${match_pattern}" <<<"${match_urls}")

    [[ -n "${filter_pattern}" && "${filter_pattern}" != "*" ]] && match_result=$(grep -Evi "${filter_pattern}" <<<"${match_urls}")
    [[ -z "${match_result}" ]] && match_result="${match_urls}"

    REMOTE_URL_LIST="${match_result}"
}

# download list format: local-save-filename remote-url remote-file-pattern match-pattern filter-pattern
# - https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest \.tar\.gz linux-musl arm|aarch64
# - https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest jq=.assets[].browser_download_url linux-musl arm|aarch64
# - https://api.github.com/repos/ajeetdsouza/zoxide/releases jq=map(select(.prerelease))|first|.assets[].browser_download_url linux-musl arm|aarch64
# -: extract filename from URL
# result: https://github.com/ajeetdsouza/zoxide/releases/download/v<version>/zoxide-<version>-x86_64-unknown-linux-musl.tar.gz
if [[ $# != 2 ]]; then
    echo "Usage: $(basename "$0") download-list download-to-directory"
    echo "eg: $(basename "$0") download-files-url.txt /tmp"
    exit 1
fi

DOWNLOAD_LIST="$1"

DOWNLOAD_DIR="$2"
[[ -z "${DOWNLOAD_DIR}" ]] && DOWNLOAD_DIR="${CURRENT_DIR}"

if [[ ! -s "${DOWNLOAD_LIST}" ]]; then
    colorEcho "${FUCHSIA}${DOWNLOAD_LIST}${RED} does not exist!"
    exit 1
fi

# colorEchoN "${ORANGE}Please input download DIR?[${CYAN}/tmp${ORANGE}]: "
# read -r DOWNLOAD_DIR
# [[ -z "${DOWNLOAD_DIR}" ]] && DOWNLOAD_DIR="/tmp"
# if [[ ! -d "${DOWNLOAD_DIR}" ]]; then
#     colorEcho "${FUCHSIA}${DOWNLOAD_DIR}${RED} does not exist or not a valid directory!"
#     exit 1
# fi

if [[ ! -d "${DOWNLOAD_DIR}" ]]; then
    colorEcho "${FUCHSIA}${DOWNLOAD_DIR}${RED} does not exist!"
    exit 1
fi

GLOBAL_MATCH_PATTERN=""
GLOBAL_FITLER_PATTERN=""
GLOBAL_REMOVE_FILE_VERSION=false
while read -r TargetList; do
    [[ -z "${TargetList}" ]] && continue

    TargetFile=$(awk '{print $1}' <<<"${TargetList}")
    [[ -z "${TargetFile}" || "${TargetFile}" == "#" ]] && continue

    TargetUrl=$(awk '{print $2}' <<<"${TargetList}")
    [[ -z "${TargetUrl}" ]] && continue

    # global options
    [[ "${TargetFile}" == "GLOBAL_MATCH_PATTERN" ]] && GLOBAL_MATCH_PATTERN="${TargetUrl}" && continue
    [[ "${TargetFile}" == "GLOBAL_FILTER_PATTERN" ]] && GLOBAL_FILTER_PATTERN="${TargetUrl}" && continue
    [[ "${TargetFile}" == "GLOBAL_REMOVE_FILE_VERSION" ]] && GLOBAL_REMOVE_FILE_VERSION="${TargetUrl}" && continue

    # get download file url that match patterns
    TargetFilePattern=$(awk '{print $3}' <<<"${TargetList}")
    TargetMatchPattern=$(awk '{print $4}' <<<"${TargetList}")
    TargetFilterPattern=$(awk '{print $5}' <<<"${TargetList}")
    if [[ -n "${TargetFilePattern}" ]]; then
        colorEcho "${BLUE}Checking download url from ${FUCHSIA}${TargetUrl}${BLUE}..."
        [[ -z "${TargetMatchPattern}" ]] && TargetMatchPattern="${GLOBAL_MATCH_PATTERN}"
        [[ -z "${TargetFilterPattern}" ]] && TargetFilterPattern="${GLOBAL_FILTER_PATTERN}"
        if ! get_remote_download_list "${TargetUrl}" "${TargetFilePattern}" "${TargetMatchPattern}" "${TargetFilterPattern}"; then
            continue
        fi
    else
        REMOTE_URL_LIST="${TargetUrl}"
    fi

    [[ -z "${REMOTE_URL_LIST}" ]] && continue

    while read -r DOWNLOAD_URL; do
        [[ -z "${DOWNLOAD_URL}" ]] && continue

        if [[ "${TargetFile}" == "-" ]]; then
            # extract filename from URL
            DOWNLOAD_FILENAME=$(basename "${DOWNLOAD_URL}" | cut -d'?' -f1)
        else
            DOWNLOAD_FILENAME="${TargetFile}"
        fi

        # remove version string if download filename contains version
        if [[ "${GLOBAL_REMOVE_FILE_VERSION}" == "true" ]]; then
            FILE_VERSION=$(grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' <<<"${DOWNLOAD_FILENAME}")
            [[ -n "${FILE_VERSION}" ]] && DOWNLOAD_FILENAME=$(sed "s/[vV_\.\-]*${FILE_VERSION}//g" <<<"${DOWNLOAD_FILENAME}")
        fi

        # use github mirror if download from github
        DOWNLOAD_FROM_GITHUB="N"
        if [[ -n "${GITHUB_DOWNLOAD_URL}" ]]; then
            if grep -q -E "^https://github.com" <<<"${DOWNLOAD_URL}"; then
                DOWNLOAD_FROM_GITHUB="Y"
                DOWNLOAD_URL="${DOWNLOAD_URL//https:\/\/github.com/${GITHUB_DOWNLOAD_URL}}"
            fi
        fi

        colorEcho "${BLUE}Downloading ${FUCHSIA}${DOWNLOAD_URL}${BLUE} to ${ORANGE}${DOWNLOAD_DIR}/${DOWNLOAD_FILENAME}${BLUE}..."

        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
        curl_download_status=$?

        if [[ ${curl_download_status} -gt 0 && "${DOWNLOAD_FROM_GITHUB}" == "Y" && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
            DOWNLOAD_URL="${DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
            colorEcho "${BLUE}  From ${ORANGE}${DOWNLOAD_URL}"
            axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/${DOWNLOAD_FILENAME}" "${DOWNLOAD_URL}"
            curl_download_status=$?
        fi

        if [[ ${curl_download_status} -eq 0 ]]; then
            mv -f "${WORKDIR}/${DOWNLOAD_FILENAME}" "${DOWNLOAD_DIR}/${DOWNLOAD_FILENAME}"
        fi
    done <<<"${REMOTE_URL_LIST}"

    echo ""
done < "${DOWNLOAD_LIST}"

cd "${CURRENT_DIR}" || exit