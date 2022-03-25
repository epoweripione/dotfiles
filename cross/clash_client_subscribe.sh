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

# fix "command not found" when running via cron
DirList=(
    "/usr/local/sbin"
    "/usr/local/bin"
    "/usr/sbin"
    "/usr/bin"
    "/sbin"
    "/bin"
)
for TargetDir in "${DirList[@]}"; do
    [[ -d "${TargetDir}" && ":$PATH:" != *":${TargetDir}:"* ]] && PATH="${TargetDir}:$PATH"
done

# yq
if [[ ! -x "$(command -v yq)" ]]; then
    AppInstaller="${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/yq_installer.sh"
    [[ -s "${AppInstaller}" ]] && source "${AppInstaller}"
fi

# if [[ ! -x "$(command -v yq)" ]]; then
#     colorEcho "${FUCHSIA}yq${RED} is not installed!"
#     exit 1
# fi

SUB_LIST_LINE=${1:-""}

mkdir -p "/srv/clash"
TARGET_CONFIG_FILE="/srv/clash/config.yaml"

SUB_LIST_FILE="/etc/clash/clash_client_subscription.list"
[[ ! -s "${SUB_LIST_FILE}" ]] && SUB_LIST_FILE="$HOME/clash_client_subscription.list"
[[ ! -s "${SUB_LIST_FILE}" ]] && SUB_LIST_FILE="${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_client_subscription.list"

[[ ! -s "${SUB_LIST_FILE}" ]] && colorEcho "${RED}Can't find ${FUCHSIA}clash_client_subscription.list${RED}!" && exit 1

DNS_CONIFG_FILE="/etc/clash/clash_client_dns.yaml"
[[ ! -s "${DNS_CONIFG_FILE}" ]] && DNS_CONIFG_FILE="$HOME/clash_client_dns.yaml"

if [[ ! -s "${DNS_CONIFG_FILE}" ]]; then
    tee -a "${DNS_CONIFG_FILE}" >/dev/null <<-'EOF'
dns:
  enable: true
  listen: 127.0.0.1:8053
  ipv6: true

  enhanced-mode: redir-host
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
if [[ -z "${SUB_LIST_LINE}" ]]; then
    # || In case the file has an incomplete (missing newline) last line
    while read -r READLINE || [[ "${READLINE}" ]]; do
        [[ "${READLINE}" =~ ^#.* ]] && continue
        SUB_LIST+=("${READLINE}")
    done < "${SUB_LIST_FILE}"
else
    SUB_LIST_CONTENT=$(sed -e '/^$/d' -e '/^#/d' "${SUB_LIST_FILE}")
    SUB_CNT=$(echo "${SUB_LIST_CONTENT}" | wc -l)

    # random line
    [[ "${SUB_LIST_LINE}" == "0" ]] && SUB_LIST_LINE=$(( ( RANDOM % 10 )  + SUB_CNT - 9 + 1 ))
    SUB_URL=$(echo "${SUB_LIST_CONTENT}" | sed -n "${SUB_LIST_LINE}p")

    # empty URL fallback to line 1
    [[ -z "${SUB_URL}" ]] && SUB_LIST_LINE="1"
    SUB_URL=$(echo "${SUB_LIST_CONTENT}" | sed -n "${SUB_LIST_LINE}p")

    [[ -z "${SUB_URL}" ]] && colorEcho "${RED}Can't get URL from line ${FUCHSIA}${SUB_LIST_LINE}${RED}!" && exit 1

    SUB_LIST+=("${SUB_URL}")
fi

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
            if [[ $(systemctl is-enabled clash 2>/dev/null) ]]; then
                colorEcho "${BLUE}Checking clash connectivity..."
                sudo systemctl restart clash && sleep 3

                if check_socks5_proxy_up "127.0.0.1:7890"; then
                    colorEcho "${GREEN}The configuration looks ok, done!"
                    exit 0
                else
                    colorEcho "${RED}Connection failed!"
                fi
            else
                exit 0
            fi
        else
            break
        fi
    done
done

cd "${CURRENT_DIR}" || exit