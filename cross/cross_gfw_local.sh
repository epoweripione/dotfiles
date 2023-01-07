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

# Run proxy client from local env variables
[[ -s "$HOME/.proxy.env.local" ]] && source "$HOME/.proxy.env.local"

if [[ -s "$HOME/.proxy.env.local" ]]; then
    source "$HOME/.proxy.env.local"
else
    colorEcho "${RED}Can't find ${FUCHSIA}.proxy.env.local${RED}!"
    exit 1
fi

[[ -z "${PROXY_WORKDIR}" ]] && PROXY_WORKDIR="$HOME/Proxy" && mkdir -p "${PROXY_WORKDIR}"
[[ -z "${PROXY_ADDRESS}" ]] && PROXY_IP="127.0.0.1" && PROXY_ADDRESS="${PROXY_IP}:7890"

for TargetApp in "${DOWNLOAD_APPS[@]}"; do
    [[ -z "${TargetApp}" ]] && continue

    APP_NAME=$(cut -d# -f1 <<<"${TargetApp}")
    APP_DOWNLOAD_NAME=$(cut -d# -f2 <<<"${TargetApp}")
    APP_DOWNLOAD_URL=$(cut -d# -f3 <<<"${TargetApp}")
    [[ -s "${PROXY_WORKDIR}/${APP_NAME}" ]] && continue

    if grep -q -E "^https://github.com" <<<"${APP_DOWNLOAD_URL}"; then
        APP_DOWNLOAD_URL="${APP_DOWNLOAD_URL//https:\/\/github.com/${GITHUB_DOWNLOAD_URL}}"
    fi

    if grep -q -E "^https://raw.githubusercontent.com" <<<"${APP_DOWNLOAD_URL}"; then
        APP_DOWNLOAD_URL="${APP_DOWNLOAD_URL//https:\/\/raw.githubusercontent.com/${GITHUB_RAW_URL}}"
    fi

    colorEcho "${BLUE}Downloading ${FUCHSIA}${APP_NAME}${BLUE} from ${ORANGE}${APP_DOWNLOAD_URL}${BLUE}..."

    curl -fSL --connect-timeout 5 -o "${WORKDIR}/${APP_DOWNLOAD_NAME}" "${APP_DOWNLOAD_URL}"
    curl_download_status=$?
    if [[ ${curl_download_status} -eq 0 ]]; then
        if Archive_File_Extract "${WORKDIR}/${APP_DOWNLOAD_NAME}" "${WORKDIR}"; then
            [[ -s "${WORKDIR}/${APP_DOWNLOAD_NAME}" ]] && mv -f "${WORKDIR}/${APP_DOWNLOAD_NAME}" "${PROXY_WORKDIR}/${APP_DOWNLOAD_NAME}"

            EXTRACT_FILE=$(find "${WORKDIR}" -type f -name "${APP_NAME}")
            [[ -s "${EXTRACT_FILE}" ]] && mv -f "${EXTRACT_FILE}" "${PROXY_WORKDIR}/${APP_NAME}"
        fi
    fi
done

# naiveproxy
if [[ -s "${PROXY_WORKDIR}/naive" ]]; then
    colorEcho "${BLUE}Running ${FUCHSIA}naiveproxy${BLUE}..."

    sudo pkill -f "naive"
    chmod +x "${PROXY_WORKDIR}/naive"

    for TargetUrl in "${NAIVEPROXY_URL[@]}"; do
        [[ -z "${TargetUrl}" ]] && continue
        nohup "${PROXY_WORKDIR}/naive" --listen="socks://127.0.0.1:${NAIVEPROXY_PORT}" --proxy="${TargetUrl}" >/dev/null 2>&1 &
        NAIVEPROXY_PORT=$((NAIVEPROXY_PORT + 1))
    done

    ps -fC "naive"
    # htop -p "$(pgrep -d, naive)"
fi

# clash
if [[ -s "${PROXY_WORKDIR}/clash" && -s "${PROXY_WORKDIR}/config.yaml" ]]; then
    colorEcho "${BLUE}Running ${FUCHSIA}clash${BLUE}..."

    sudo pkill -f "clash"
    chmod +x "${PROXY_WORKDIR}/clash"
    nohup "${PROXY_WORKDIR}/clash" -d "${PROXY_WORKDIR}" >/dev/null 2>&1 &

    ps -fC "clash"
    # htop -p "$(pgrep -d, clash)"
fi

if check_http_proxy_up "${PROXY_ADDRESS}" "www.google.com"; then
    PROXY_ADDRESS="http://${PROXY_ADDRESS}"
    # export {http,https,ftp,all}_proxy="${PROXY_ADDRESS}" && export {HTTP,HTTPS,FTP,ALL}_PROXY="${PROXY_ADDRESS}"

    colorEcho "${GREEN}Usage:"
    colorEcho "${BLUE}  export {http,https,ftp,all}_proxy=\"${PROXY_ADDRESS}\""
    colorEcho "${BLUE}  export {HTTP,HTTPS,FTP,ALL}_PROXY=\"${PROXY_ADDRESS}\""
else
    colorEcho "${RED}Setting proxy failed!"
    exit 1
fi
