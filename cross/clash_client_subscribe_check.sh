#!/usr/bin/env bash

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

function check_url_status() {
    local url_host=$1
    local url_test=$2
    local http exitStatus=0

    http=$(curl -fsL --noproxy "*" --connect-timeout 3 --max-time 5 \
        -w "%{http_code}\\n" "${url_test}" -o /dev/null)
    case "${http}" in
        [2]*)
            colorEcho "${BLUE}${url_host}${GREEN}  UP ${FUCHSIA}${http} ${GREEN}✓"
            ;;
        [3]*)
            colorEcho "${BLUE}${url_host}${GREEN} REDIRECT ${FUCHSIA}${http} ${GREEN}✓"
            ;;
        [4]*)
            if [[ "${http}" = "400" ]]; then
                colorEcho "${BLUE}${url_host}${ORANGE} Bad Request ${FUCHSIA}${http} ${GREEN}✓"
            else
                exitStatus=4
                colorEcho "${BLUE}${url_host}${RED} DENIED ${FUCHSIA}${http} ${RED}✕"
            fi
            ;;
        [5]*)
            exitStatus=5
            colorEcho "${BLUE}${url_host}${RED} ERROR ${FUCHSIA}${http} ${RED}✕"
            ;;
        *)
            exitStatus=6
            colorEcho "${BLUE}${url_host}${RED} NO RESPONSE ${FUCHSIA}${http} ${RED}✕"
            ;;
    esac

    [[ "${exitStatus}" -eq "0" ]] && return 0 || return 1
}

# usage: ${MY_SHELL_SCRIPTS}/cross/clash_client_subscripe_check.sh $HOME/clash_client_subscription.list
if [[ $# != 1 ]]; then
    echo "Usage: $(basename "$0") url-list-file"
    echo "eg: $(basename "$0") clash_client_subscription.list"
    exit 1
fi

filename="$1"
[[ ! -s "${filename}" ]] && echo "${filename} does not exist!" && exit 1

URL_EXCLUDE=$(grep -E '^# exclude=' "${filename}" | cut -d" " -f2 | head -n1)
URL_CONFIG=$(grep -E '^# config=' "${filename}" | cut -d" " -f2 | head -n1)
URL_URL=$(grep -E '^# url=' "${filename}" | cut -d" " -f2 | cut -d"=" -f2 | head -n1)

FAIL_URL=()

while read -r line; do
    [[ -z "${line}" ]] && continue

    TARGET_HOST=$(cut -d' ' -f1 <<<"${line}")
    [[ "${TARGET_HOST}" == "#" ]] && continue

    # https://www.example.com/sub?target=clash&url=<url>&config=<config>&exclude=<exclude>
    if grep -q 'sub?target=' <<<"${TARGET_HOST}"; then
        TARGET_URL="${TARGET_HOST}&url=${URL_URL}&${URL_CONFIG}"
    else
        TARGET_URL="${TARGET_HOST}sub?target=clash&url=${URL_URL}&${URL_CONFIG}"
    fi

    [[ -n "${URL_EXCLUDE}" ]] && TARGET_URL="${TARGET_URL}&${URL_EXCLUDE}"

    if ! check_url_status "${TARGET_HOST}" "${TARGET_URL}"; then
        FAIL_URL+=("${TARGET_HOST}")
    fi
done < "${filename}"

# comment failed url
for TargetURL in "${FAIL_URL[@]}"; do
    [[ -z "${TargetURL}" ]] && continue

    sed -i "s|^${TargetURL}|# &|g" "${filename}"
done
