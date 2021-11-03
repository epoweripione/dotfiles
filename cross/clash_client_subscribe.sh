#!/usr/bin/env bash

# Usage:
# ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_client_subscribe.sh 1

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

SUB_LIST_LINE=${1:-""}
SUB_DOWNLOAD_FILE="${WORKDIR}/clash_sub.yaml"

mkdir -p "/srv/clash"
TARGET_CONFIG_FILE="/srv/clash/config.yaml"

SUB_LIST_FILE="/etc/clash/clash_client_subscription.list"
[[ ! -s "$SUB_LIST_FILE" ]] && SUB_LIST_FILE="$HOME/clash_client_subscription.list"
[[ ! -s "$SUB_LIST_FILE" ]] && SUB_LIST_FILE="${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_client_subscription.list"

[[ ! -s "$SUB_LIST_FILE" ]] && colorEcho "${RED}Can't find ${FUCHSIA}clash_client_subscription.list${RED}!" && exit 1

if [[ -z "$SUB_LIST_LINE" ]]; then
    SUB_LIST=()
    # || In case the file has an incomplete (missing newline) last line
    while read -r READLINE || [[ "$READLINE" ]]; do
        SUB_LIST+=("$READLINE")
    done < "${SUB_LIST_FILE}"

    for TargetURL in "${SUB_LIST[@]}"; do
        [[ -z "$TargetURL" ]] && continue
        colorEcho "${BLUE}Downloading clash client connfig from ${FUCHSIA}${TargetURL}${BLUE}..."
        curl -fSL --noproxy "*" --connect-timeout 10 --max-time 60 \
            -o "$SUB_DOWNLOAD_FILE" "$TargetURL"

        curl_download_status=$?
        if [[ ${curl_download_status} -eq 0 ]]; then
            sed -i "s/^allow-lan:.*/allow-lan: false/" "$SUB_DOWNLOAD_FILE"
            sed -i "s/^external-controller:.*/# &/" "$SUB_DOWNLOAD_FILE"
            sudo cp -f "$SUB_DOWNLOAD_FILE" "$TARGET_CONFIG_FILE"
            exit 0
        fi
    done
else
    SUB_LIST_CONTENT=$(sed '/^$/d' "${SUB_LIST_FILE}")
    SUB_LIST_COUNT=$(echo "${SUB_LIST_CONTENT}" | wc -l)

    # random line
    [[ "${SUB_LIST_LINE}" == "0" ]] && SUB_LIST_LINE=$(( ( RANDOM % 10 )  + SUB_LIST_COUNT - 9 + 1 ))
    TargetURL=$(echo "${SUB_LIST_CONTENT}" | sed -n "${SUB_LIST_LINE}p")

    # empty URL fallback to line 1
    [[ -z "$TargetURL" ]] && SUB_LIST_LINE="1"
    TargetURL=$(echo "${SUB_LIST_CONTENT}" | sed -n "${SUB_LIST_LINE}p")

    [[ -z "$TargetURL" ]] && colorEcho "${RED}Can't get URL from line ${FUCHSIA}${SUB_LIST_LINE}${RED}!" && exit 1

    colorEcho "${BLUE}Downloading clash client connfig from ${FUCHSIA}${TargetURL}${BLUE}..."
    curl -fSL --noproxy "*" --connect-timeout 10 --max-time 60 \
        -o "$SUB_DOWNLOAD_FILE" "$TargetURL"

    curl_download_status=$?
    if [[ ${curl_download_status} -eq 0 ]]; then
        sed -i "s/^allow-lan:.*/allow-lan: false/" "$SUB_DOWNLOAD_FILE"
        sed -i "s/^external-controller:.*/# &/" "$SUB_DOWNLOAD_FILE"
        sudo cp -f "$SUB_DOWNLOAD_FILE" "$TARGET_CONFIG_FILE"
        exit 0
    fi
fi

cd "${CURRENT_DIR}" || exit