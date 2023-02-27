#!/usr/bin/env bash

# Colors
NOCOLOR='\033[0m'
RED='\033[0;31m'        # Error message
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'      # Success message
LIGHTGREEN='\033[1;32m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'     # Warning message
BLUE='\033[0;34m'       # Info message
LIGHTBLUE='\033[1;34m'
PURPLE='\033[0;35m'
FUCHSIA='\033[0;35m'
LIGHTPURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHTCYAN='\033[1;36m'
DARKGRAY='\033[1;30m'
LIGHTGRAY='\033[0;37m'
WHITE='\033[1;37m'

function colorEcho() {
    if [[ $# -gt 1 ]]; then
        local COLOR=$1
        echo -e "${COLOR}${@:2}${NOCOLOR}"
    else
        echo -e "${@:1}${NOCOLOR}"
    fi
}

function check_socks5_proxy_up() {
    local socks_proxy_url=${1:-"127.0.0.1:1080"}
    local webservice_url=${2:-"www.google.com"}
    local exitStatus=0

    curl -fsL -I --connect-timeout 3 --max-time 5 \
        --socks5-hostname "${socks_proxy_url}" \
        "${webservice_url}" >/dev/null 2>&1 || exitStatus=$?

    if [[ "$exitStatus" -eq "0" ]]; then
        return 0
    else
        return 1
    fi
}

function Install_systemd_Service() {
    # Usage:
    # Install_systemd_Service "subconverter" "/srv/subconverter/subconverter"
    local service_name=$1
    local service_exec=$2
    local service_user=${3:-"nobody"}
    local service_workdir=${4:-""}
    local filename
    local service_file

    [[ $# -lt 2 ]] && return 1
    [[ -z "$service_name" ]] && return 1
    [[ -z "$service_exec" ]] && return 1

    if [[ -z "$service_workdir" ]]; then
        filename=$(echo "${service_exec}" | cut -d" " -f1)
        service_workdir=$(dirname "$(readlink -f "$filename")")
    fi

    service_file="/etc/systemd/system/${service_name}.service"
    if [[ ! -s "$service_file" ]]; then
        sudo tee "$service_file" >/dev/null <<-EOF
[Unit]
Description=${service_name}
After=network.target network-online.target nss-lookup.target

[Service]
Type=simple
StandardError=journal
User=${service_user}
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=${service_exec}
WorkingDirectory=${service_workdir}
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    fi

    sudo systemctl enable "$service_name" && sudo systemctl restart "$service_name"
    if systemctl is-enabled "$service_name" >/dev/null 2>&1; then
        colorEcho "${GREEN}  systemd service ${FUCHSIA}${service_name}${GREEN} installed!"
    else
        colorEcho "${RED}  systemd service ${FUCHSIA}${service_name}${GREEN} install failed!"
    fi
}


trap 'rm -rf "${WORKDIR}"' EXIT
[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"

DOWNLOAD_URL=${1:-""}
SUB_LIST_FILE=${2:-"/etc/clash/clash_client_subscription.list"}


if [[ ! -d "/srv/clash" ]]; then
    if [[ -z "${DOWNLOAD_URL}" ]]; then
        [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/subconverter_installer.sh" ]] && \
            source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/subconverter_installer.sh"

        [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_installer.sh" ]] && \
            source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_installer.sh"
    else
        wget -c -O "/tmp/subconverter_clash.zip" "${DOWNLOAD_URL}" && \
            unzip -qo "/tmp/subconverter_clash.zip" -d "/srv" && \
            rm -f "/tmp/subconverter_clash.zip" && \
            Install_systemd_Service "subconverter" "/srv/subconverter/subconverter" && \
            Install_systemd_Service "clash" "/srv/clash/clash -d /srv/clash" "root" && \
            colorEcho "${GREEN}Subconverter & Clash installed!"
    fi
fi


if ! pgrep -f "clash" >/dev/null 2>&1; then
    [[ -d "/srv/subconverter" ]] && Install_systemd_Service "subconverter" "/srv/subconverter/subconverter"
    [[ -d "/srv/clash" ]] && Install_systemd_Service "clash" "/srv/clash/clash -d /srv/clash" "root"
    systemctl is-enabled clash >/dev/null 2>&1 && sudo systemctl restart clash
fi

if ! pgrep -f "clash" >/dev/null 2>&1; then
    colorEcho "${RED}Please install and run ${FUCHSIA}clash${RED} first!"
    exit 1
fi


TARGET_CONFIG_FILE="/srv/clash/config.yaml"

[[ ! -s "${SUB_LIST_FILE}" ]] && SUB_LIST_FILE="/srv/clash/clash_client_subscription.list"
[[ ! -s "${SUB_LIST_FILE}" ]] && SUB_LIST_FILE="$HOME/clash_client_subscription.list"

DNS_CONIFG_FILE="/etc/clash/clash_client_dns.yaml"
[[ ! -s "${DNS_CONIFG_FILE}" ]] && DNS_CONIFG_FILE="$HOME/clash_client_dns.yaml"

if [[ ! -s "${DNS_CONIFG_FILE}" ]]; then
    tee -a "${DNS_CONIFG_FILE}" >/dev/null <<-'EOF'
dns:
  enable: true
  listen: 127.0.0.1:8053
  ipv6: true

  fake-ip-range: 198.18.0.1/16

  nameserver:
    - 223.5.5.5
    - 114.114.114.114
    - https://dns.alidns.com/dns-query
    - "[2400:3200::1]:53"

  fallback:
    - tcp://1.1.1.1
    - tcp://8.8.8.8
    - tls://1.0.0.1:853
    - tls://dns.google:853
    - "[2606:4700:4700::1111]:53"
    - "[2620:fe::9]:53"
EOF
fi

if [[ -s "${SUB_LIST_FILE}" ]]; then
    # Subscribe urls
    URL_EXCLUDE=$(grep -E '^# exclude=' "${SUB_LIST_FILE}" | cut -d" " -f2)
    URL_CONFIG=$(grep -E '^# config=' "${SUB_LIST_FILE}" | cut -d" " -f2)
    URL_LIST_CONTENT=$(grep -E '^# url=' "${SUB_LIST_FILE}" | cut -d" " -f2 | cut -d"=" -f2)

    URL_UNION=""
    URL_LIST=()
    while read -r READLINE || [[ "${READLINE}" ]]; do
        URL_LIST+=("${READLINE}")
        [[ -n "${URL_UNION}" ]] && URL_UNION="${URL_UNION}%7C${READLINE}" || URL_UNION="${READLINE}"
    done <<<"${URL_LIST_CONTENT}"

    URL_LIST+=("${URL_UNION}")

    # Subconverter web service urls
    SUB_LIST=()
    # || In case the file has an incomplete (missing newline) last line
    while read -r READLINE || [[ "${READLINE}" ]]; do
        [[ "${READLINE}" =~ ^#.* ]] && continue
        SUB_LIST+=("${READLINE}")
    done < "${SUB_LIST_FILE}"

    # Download clash configuration file
    SUB_DOWNLOAD_FILE="${WORKDIR}/clash_sub.yaml"
    for TargetURL in "${SUB_LIST[@]}"; do
        [[ -z "${TargetURL}" ]] && continue

        for URL_URL in "${URL_LIST[@]}"; do
            [[ -z "${URL_URL}" ]] && continue

            # https://www.example.com/sub?target=clash&url=<url>&config=<config>&exclude=<exclude>
            DownloadURL="${TargetURL}&url=${URL_URL}&${URL_CONFIG}"
            [[ -n "${URL_EXCLUDE}" ]] && DownloadURL="${DownloadURL}&${URL_EXCLUDE}"

            colorEcho "${BLUE}Downloading clash configuration from ${FUCHSIA}${DownloadURL}${BLUE}..."
            curl -fSL --noproxy "*" --connect-timeout 10 --max-time 60 \
                -o "${SUB_DOWNLOAD_FILE}" "${DownloadURL}"

            curl_download_status=$?
            if [[ ${curl_download_status} -eq 0 ]]; then
                sed -i -e "s/^allow-lan:.*/allow-lan: false/" \
                    -e "s/^external-controller:.*/# &/" \
                    -e "s/^port:.*/# &/" \
                    -e "s/^redir-port:.*/# &/" \
                    -e "s/^mixed-port:.*/# &/" \
                    -e "s/^socks-port:.*/# &/" "${SUB_DOWNLOAD_FILE}"
                sed -i "1i\mixed-port: 7890\nredir-port: 7892" "${SUB_DOWNLOAD_FILE}"

                [[ -x "$(command -v yq)" ]] && DNS_ENABLE=$(yq e ".dns.enable // \"\"" "${SUB_DOWNLOAD_FILE}")
                [[ -z "${DNS_ENABLE}" && -s "${DNS_CONIFG_FILE}" ]] && sed -i "/^redir-port/r ${DNS_CONIFG_FILE}" "${SUB_DOWNLOAD_FILE}"

                sudo cp -f "${SUB_DOWNLOAD_FILE}" "${TARGET_CONFIG_FILE}"

                # if pgrep -f "clash" >/dev/null 2>&1; then
                if systemctl is-enabled clash >/dev/null 2>&1; then
                    colorEcho "${BLUE}Checking clash connectivity..."
                    sudo systemctl restart clash && sleep 3

                    if check_socks5_proxy_up "127.0.0.1:7890"; then
                        colorEcho "${GREEN}The configuration looks ok, done!"
                        break 2
                    else
                        colorEcho "${RED}Connection failed!"
                    fi
                else
                    break 2
                fi
            else
                break
            fi
        done
    done
fi


if [[ "$(uname -r)" =~ "microsoft" ]]; then
    # WSL2
    # Fix "Invalid argument" when executing Windows commands
    CMD_DIR=$(dirname "$(which ipconfig.exe)")
    PROXY_IP=$(cd "${CMD_DIR}" && ipconfig.exe | grep "IPv4" \
                | grep -Eo '([0-9]{1,3}[\.]){3}[0-9]{1,3}' \
                | grep -Ev "^0\.|^127\.|^172\." \
                | head -n1)
    # PROXY_IP=$(grep -m1 nameserver /etc/resolv.conf | awk '{print $2}')
    # PROXY_ADDRESS="socks5://${PROXY_IP}:7890"
    # export {http,https,ftp,all}_proxy=${PROXY_ADDRESS} && export {HTTP,HTTPS,FTP,ALL}_PROXY=${PROXY_ADDRESS}
    # git config --global http.proxy \"${PROXY_ADDRESS}\" && git config --global https.proxy \"${PROXY_ADDRESS}\"
else
    PROXY_IP="127.0.0.1"
fi

PROXY_ADDRESS=""
if check_socks5_proxy_up "${PROXY_IP}:7890"; then
    PROXY_ADDRESS="${PROXY_IP}:7890"
elif check_socks5_proxy_up "${PROXY_IP}:7891"; then
    PROXY_ADDRESS="${PROXY_IP}:7891"
fi

if [[ -z "${PROXY_ADDRESS}" ]]; then
    colorEcho "${RED}Error when setting socks5 proxy!"
    exit 1
fi

PROXY_ADDRESS="socks5://${PROXY_ADDRESS}"

colorEcho "${GREEN}Usage:"
colorEcho "${BLUE}  export {http,https,ftp,all}_proxy=\"${PROXY_ADDRESS}\""
colorEcho "${BLUE}  export {HTTP,HTTPS,FTP,ALL}_PROXY=\"${PROXY_ADDRESS}\""
# colorEcho "${BLUE}  git config --global http.proxy \"${PROXY_ADDRESS}\""
# colorEcho "${BLUE}  git config --global https.proxy \"${PROXY_ADDRESS}\""

unset PROXY_IP
unset PROXY_ADDRESS

colorEcho "${GREEN}Done!"