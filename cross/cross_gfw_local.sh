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

## Run proxy client from local env variables
# PROXY_WORKDIR="$HOME/Proxy"
# PROXY_IP="127.0.0.1" && PROXY_ADDRESS="${PROXY_IP}:7890"
# [[ -z "${GITHUB_DOWNLOAD_URL}" ]] && GITHUB_DOWNLOAD_URL="https://github.com"
# [[ -z "${GITHUB_RAW_URL}" ]] && GITHUB_RAW_URL="https://raw.githubusercontent.com"
# NAIVEPROXY_PORT=7895
# NAIVEPROXY_URL=(
#     "https://user:password@test.com"
#     "https://user:password@example.com"
# )
# DOWNLOAD_APPS=(
#     "naive#naiveproxy.tar.xz#https://github.com/klzgrad/naiveproxy/releases/download/v120.0.6099.43-1/naiveproxy-v120.0.6099.43-1-linux-x64.tar.xz"
#     "mihomo#mihomo.gz#https://github.com/MetaCubeX/mihomo/releases/download/v1.17.0/mihomo-linux-amd64-v1.17.0.gz"
#     "mieru#mieru.tar.gz#https://github.com/enfein/mieru/releases/download/v2.2.0/mieru_2.2.0_linux_amd64.tar.gz"
#     "Country.mmdb#Country.mmdb#https://github.com/Hackl0us/GeoIP2-CN/raw/release/Country.mmdb"
#     "geoip.dat#geoip.dat#https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat"
#     "geosite.dat#geosite.dat#https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
#     "config.yaml#config.yaml#https://www.test.com/config.yaml"
# )

if [[ -s "$HOME/.proxy.env.local" ]]; then
    source "$HOME/.proxy.env.local"
else
    colorEcho "${RED}Can't find ${FUCHSIA}.proxy.env.local${RED}!"
    exit 1
fi

[[ -z "${PROXY_WORKDIR}" ]] && PROXY_WORKDIR="$HOME/Proxy"
[[ ! -d "${PROXY_WORKDIR}" ]] && mkdir -p "${PROXY_WORKDIR}"

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
            EXTRACT_FILE=$(find "${WORKDIR}" -type f -name "${APP_NAME}")
            [[ -s "${EXTRACT_FILE}" ]] && mv -f "${EXTRACT_FILE}" "${PROXY_WORKDIR}/${APP_NAME}"
        else
            mv -f "${WORKDIR}/${APP_DOWNLOAD_NAME}" "${PROXY_WORKDIR}/${APP_DOWNLOAD_NAME}"
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

# mihomo
if [[ -s "${PROXY_WORKDIR}/mihomo" && -s "${PROXY_WORKDIR}/config.yaml" ]]; then
    colorEcho "${BLUE}Running ${FUCHSIA}mihomo${BLUE}..."

    sudo pkill -f "mihomo"
    chmod +x "${PROXY_WORKDIR}/mihomo"
    nohup "${PROXY_WORKDIR}/mihomo" -d "${PROXY_WORKDIR}" >/dev/null 2>&1 &

    ps -fC "mihomo"
    # htop -p "$(pgrep -d, mihomo)"
fi

# mieru
if [[ -s "${PROXY_WORKDIR}/mieru" && -s "${MIERU_CONFIG}" ]]; then
    colorEcho "${BLUE}Running ${FUCHSIA}mieru${BLUE}..."

    sudo pkill -f "mieru"
    chmod +x "${PROXY_WORKDIR}/mieru"
    "${PROXY_WORKDIR}/mieru" apply config "${MIERU_CONFIG}"
    nohup "${PROXY_WORKDIR}/mieru" start >/dev/null 2>&1 &

    ps -fC "mieru"
    # htop -p "$(pgrep -d, mieru)"
fi

sleep 3

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
