#!/usr/bin/env bash

# Usage:
# ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_to_surge.sh /srv/web/www/public/public.yml /srv/web/www/public/public.ini
# for file in /srv/web/www/public/*.yml; do ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/clash_to_surge.sh "${file}"; done


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

CONFIG_SRC=${1:-""}
if [[ -z "${CONFIG_SRC}" ]]; then
    colorEcho "${FUCHSIA}Source file${RED} can't empty!"
    exit 1
elif [[ ! -s "${CONFIG_SRC}" ]]; then
    colorEcho "${FUCHSIA}Source file${RED} does not exist!"
    exit 1
fi

CONFIG_SRC_DIR=$(dirname -- "${CONFIG_SRC}")
CONFIG_SRC_NAME="${CONFIG_SRC##*/}"
CONFIG_SRC_EXT="${CONFIG_SRC_NAME##*.}"
CONFIG_SRC_NAME="${CONFIG_SRC_NAME%.*}"

CONFIG_TO=${2:-""}
[[ -z "${CONFIG_TO}" && "${CONFIG_SRC_EXT}" != "ini" ]] && CONFIG_TO="${CONFIG_SRC_DIR}/${CONFIG_SRC_NAME}.ini"
if [[ -z "${CONFIG_TO}" ]]; then
    colorEcho "${FUCHSIA}Target file${RED} can't empty!"
    exit 1
fi

AutoUpdateUrl=${3:-""}

function setProxies() {
    if [[ -n "${PROXY_NAME_PRE}" ]]; then
        OUTPUT_LINE="${PROXY_NAME_PRE} = ${PROXY_TYPE}"
        [[ -n "${PROXY_SERVER}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, ${PROXY_SERVER}"
        [[ -n "${PROXY_PORT}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, ${PROXY_PORT}"

        if [[ "${PROXY_TYPE}" == "http" || "${PROXY_TYPE}" == "https" || "${PROXY_TYPE}" == "socks5" ]]; then
            [[ -n "${PROXY_USERNAME}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, ${PROXY_USERNAME}"
            [[ -n "${PROXY_PASSWORD}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, ${PROXY_PASSWORD}"
        else
            [[ -n "${PROXY_USERNAME}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, username=${PROXY_USERNAME}"
            [[ -n "${PROXY_UUID}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, username=${PROXY_UUID}"
            [[ -n "${PROXY_PASSWORD}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, password=${PROXY_PASSWORD}"
        fi

        [[ "${PROXY_NETWORK}" == "ws" ]] && OUTPUT_LINE="${OUTPUT_LINE}, ws=true"
        [[ "${PROXY_UDP}" == "true" ]] && OUTPUT_LINE="${OUTPUT_LINE}, udp-relay=true"
        [[ "${PROXY_UDP}" == "false" ]] && OUTPUT_LINE="${OUTPUT_LINE}, udp-relay=false"

        if [[ "${PROXY_TYPE}" == "vmess" ]]; then
            [[ -n "${PROXY_PATH}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, ws-path=${PROXY_PATH}"
            [[ -n "${PROXY_HEADER}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, ws-headers=${PROXY_HEADER}"
        fi

        [[ -n "${PROXY_CIPHER}" && "${PROXY_CIPHER}" != "auto" ]] && OUTPUT_LINE="${OUTPUT_LINE}, encrypt-method=${PROXY_CIPHER}"
        [[ -n "${PROXY_SKIP_CERT_VERIFY}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, skip-cert-verify=${PROXY_SKIP_CERT_VERIFY}"
        [[ -n "${PROXY_SNI}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, sni=${PROXY_SNI}"

        if [[ "${PROXY_TYPE}" == "vmess" ]]; then
            [[ "${PROXY_ALTERID}" == "0" ]] && OUTPUT_LINE="${OUTPUT_LINE}, vmess-aead=true"
            [[ -n "${PROXY_ALTERID}" && "${PROXY_ALTERID}" != "0" ]] && OUTPUT_LINE="${OUTPUT_LINE}, vmess-aead=false"
        fi

        [[ -n "${PROXY_TLS}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, tls=${PROXY_TLS}"

        if [[ -n "${PROXY_PLUGIN}" ]]; then
            [[ -n "${PROXY_PLUGIN_MODE}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, obfs=${PROXY_PLUGIN_MODE}"
            [[ -n "${PROXY_PLUGIN_HOST}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, obfs-host=${PROXY_PLUGIN_HOST}"
            [[ -n "${PROXY_PLUGIN_PATH}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, obfs-uri=${PROXY_PLUGIN_PATH}"
        fi

        echo "${OUTPUT_LINE}" | sed -e 's/\s#.*//g' -e 's/"//g' -e "s/'//g" | tee -a "${CONFIG_TO}" >/dev/null
    fi

    PROXY_NAME_PRE="${PROXY_NAME}"

    PROXY_NAME=""
    PROXY_TYPE=""
    PROXY_SERVER=""
    PROXY_PORT=""
    PROXY_USERNAME=""
    PROXY_UUID=""
    PROXY_PASSWORD=""
    PROXY_NETWORK=""
    PROXY_UDP=""
    PROXY_PATH=""
    PROXY_HEADER=""
    PROXY_CIPHER=""
    PROXY_SKIP_CERT_VERIFY=""
    PROXY_SNI=""
    PROXY_ALTERID=""
    PROXY_PLUGIN=""
    PROXY_PLUGIN_MODE=""
    PROXY_PLUGIN_HOST=""
    PROXY_PLUGIN_PATH=""
}

function setProxyGroup() {
    if [[ -n "${GROUP_NAME_PRE}" ]]; then
        OUTPUT_LINE="${GROUP_NAME_PRE} = ${GROUP_TYPE}, ${GROUP_PROXIES}"
        [[ -n "${GROUP_URL}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, url=${GROUP_URL}"
        [[ -n "${GROUP_INTERVAL}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, interval=${GROUP_INTERVAL}"
        [[ -n "${GROUP_TOLERANCE}" ]] && OUTPUT_LINE="${OUTPUT_LINE}, tolerance=${GROUP_TOLERANCE}"

        echo "${OUTPUT_LINE}" | sed -e 's/\s#.*//g' -e 's/"//g' -e "s/'//g" | tee -a "${CONFIG_TO}" >/dev/null
    fi

    GROUP_NAME_PRE="${GROUP_NAME}"

    GROUP_NAME=""
    GROUP_PROXIES_START="no"
    GROUP_TYPE=""
    GROUP_URL=""
    GROUP_INTERVAL=""
    GROUP_TOLERANCE=""
}

# fix "command not found" when running via cron
FixSystemBinPath

colorEcho "${BLUE}Converting ${ORANGE}${CONFIG_SRC} ${BLUE}to${FUCHSIA} ${CONFIG_TO}${BLUE}..."

# surge config auto update URL 
if [[ -n "${AutoUpdateUrl}" ]]; then
    echo "#!MANAGED-CONFIG ${AutoUpdateUrl} interval=18000 strict=false" | tee "${CONFIG_TO}" >/dev/null
    echo '' | tee -a "${CONFIG_TO}" >/dev/null
else
    echo '' | tee "${CONFIG_TO}" >/dev/null
fi

# General
colorEcho "${BLUE}  Processing ${FUCHSIA}[General]${BLUE}..."
tee -a "${CONFIG_TO}" >/dev/null <<-'EOF'
[General]
loglevel = notify
interface = 127.0.0.1
skip-proxy = 127.0.0.1, 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, 100.64.0.0/10, localhost, *.local

ipv6 = false

dns-server = system, 223.5.5.5, 223.6.6.6, 1.0.0.1, 1.1.1.1
doh-server = https://9.9.9.9/dns-query

test-timeout = 5
proxy-test-url = http://www.gstatic.com/generate_204
internet-test-url = http://www.gstatic.cn/generate_204

exclude-simple-hostnames = true
enhanced-mode-by-rule = true
udp-policy-not-supported-behaviour = DIRECT

# bypass-tun = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12
# always-real-ip = *.srv.nintendo.net, *.stun.playstation.net, xbox.*.microsoft.com, *.xboxlive.com

# http-listen = 0.0.0.0:7890
# socks5-listen = 127.0.0.1:7891

[Proxy]
On = direct
Off = reject

EOF

# Proxy & Proxy Group
OUTPUT_TYPE=""
while IFS= read -r READLINE || [[ "${READLINE}" ]]; do
    [[ -z "${READLINE}" ]] && continue
    grep -q -E '^\s*#' <<<"${READLINE}" && continue

    [[ "${READLINE}" == "rules:" ]] && break

    if [[ -z "${OUTPUT_TYPE}" && "${READLINE}" == "proxies:" ]]; then
        colorEcho "${BLUE}  Processing ${FUCHSIA}[Proxy]${BLUE}..."
        OUTPUT_TYPE="proxies"
        PROXY_NAME_PRE=""
        continue
    fi

    if [[ "${READLINE}" == "proxy-groups:" ]]; then
        # last proxy
        setProxies

        colorEcho "${BLUE}  Processing ${FUCHSIA}[Proxy Group]${BLUE}..."
        echo '' | tee -a "${CONFIG_TO}" >/dev/null
        echo '[Proxy Group]' | tee -a "${CONFIG_TO}" >/dev/null
        OUTPUT_TYPE="proxy-groups"
        GROUP_NAME_PRE=""
        continue
    fi

    READLINE=$(sed "s/[\"\']//g" <<<"${READLINE}")
    case "${OUTPUT_TYPE}" in
        "proxies")
            PROXY_NAME=$( (sed 's/,/\n/g' | grep 'name:' | sed 's/[{}]//g' | sed -nr 's/.*name:\s*(.+)/\1/p' | head -n1) <<<"${READLINE}")
            [[ -n "${PROXY_NAME}" ]] && setProxies

            [[ -z "${PROXY_TYPE}" ]] && PROXY_TYPE=$( (sed 's/,/\n/g' | grep 'type:' | sed 's/[{}]//g' | sed -nr 's/.*type:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${PROXY_SERVER}" ]] && PROXY_SERVER=$( (sed 's/,/\n/g' | grep 'server:' | sed 's/[{}]//g' | sed -nr 's/.*server:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${PROXY_PORT}" ]] && PROXY_PORT=$( (sed 's/,/\n/g' | grep 'port:' | sed 's/[{}]//g' | sed -nr 's/.*port:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${PROXY_USERNAME}" ]] && PROXY_USERNAME=$( (sed 's/,/\n/g' | grep 'username:' | sed 's/[{}]//g' | sed -nr 's/.*username:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${PROXY_UUID}" ]] && PROXY_UUID=$( (sed 's/,/\n/g' | grep 'uuid:' | sed 's/[{}]//g' | sed -nr 's/.*uuid:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${PROXY_PASSWORD}" ]] && PROXY_PASSWORD=$( (sed 's/,/\n/g' | grep 'password:' | sed 's/[{}]//g' | sed -nr 's/.*password:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${PROXY_NETWORK}" ]] && PROXY_NETWORK=$( (sed 's/,/\n/g' | grep 'network:' | sed 's/[{}]//g' | sed -nr 's/.*network:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${PROXY_UDP}" ]] && PROXY_UDP=$( (sed 's/,/\n/g' | grep 'udp:' | sed 's/[{}]//g' | sed -nr 's/.*udp:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${PROXY_PATH}" ]] && PROXY_PATH=$( (sed 's/,/\n/g' | grep 'path:' | sed 's/[{}]//g' | sed -nr 's/.*path:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${PROXY_HEADER}" ]] && PROXY_HEADER=$( (sed 's/,/\n/g' | grep 'headers:' | sed 's/[{}]//g' | sed -nr 's/.*headers:\s*(.+)/\1/p' | sed 's/:\s/:/g') <<<"${READLINE}")
            [[ -z "${PROXY_CIPHER}" ]] && PROXY_CIPHER=$( (sed 's/,/\n/g' | grep 'cipher:' | sed 's/[{}]//g' | sed -nr 's/.*cipher:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${PROXY_SKIP_CERT_VERIFY}" ]] && PROXY_SKIP_CERT_VERIFY=$( (sed 's/,/\n/g' | grep 'skip-cert-verify:' | sed 's/[{}]//g' | sed -nr 's/.*skip-cert-verify:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${PROXY_SNI}" ]] && PROXY_SNI=$( (sed 's/,/\n/g' | grep 'sni:' | sed 's/[{}]//g' | sed -nr 's/.*sni:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${PROXY_ALTERID}" ]] && PROXY_ALTERID=$( (sed 's/,/\n/g' | grep 'alterId:' | sed 's/[{}]//g' | sed -nr 's/.*alterId:\s*(.+)/\1/p') <<<"${READLINE}")

            [[ -z "${PROXY_PLUGIN}" ]] && PROXY_PLUGIN=$( (sed 's/,/\n/g' | grep 'plugin:' | sed 's/[{}]//g' | sed -nr 's/.*plugin:\s*(.+)/\1/p') <<<"${READLINE}")
            if [[ -n "${PROXY_PLUGIN}" ]]; then
                [[ -z "${PROXY_PLUGIN_MODE}" ]] && PROXY_PLUGIN_MODE=$( (sed 's/,/\n/g' | grep 'mode:' | sed 's/[{}]//g' | sed -nr 's/.*mode:\s*(.+)/\1/p') <<<"${READLINE}")
                [[ -z "${PROXY_PLUGIN_HOST}" ]] && PROXY_PLUGIN_HOST=$( (sed 's/,/\n/g' | grep 'host:' | sed 's/[{}]//g' | sed -nr 's/.*host:\s*(.+)/\1/p') <<<"${READLINE}")
                [[ -z "${PROXY_PLUGIN_PATH}" ]] && PROXY_PLUGIN_PATH=$( (sed 's/,/\n/g' | grep 'path:' | sed 's/[{}]//g' | sed -nr 's/.*path:\s*(.+)/\1/p') <<<"${READLINE}")
            fi
            ;;
        "proxy-groups")
            # GROUP_NAME=$(sed -nr 's/\s*-\s*name:\s*(.+)/\1/p' <<<"${READLINE}")
            GROUP_NAME=$( (sed 's/,/\n/g' | grep 'name:' | sed 's/[{}]//g' | sed -nr 's/.*name:\s*(.+)/\1/p' | head -n1) <<<"${READLINE}")
            [[ -n "${GROUP_NAME}" ]] && setProxyGroup

            [[ -z "${GROUP_TYPE}" ]] && GROUP_TYPE=$( (sed 's/,/\n/g' | grep 'type:' | sed 's/[{}]//g' | sed -nr 's/.*type:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${GROUP_URL}" ]] && GROUP_URL=$( (sed 's/,/\n/g' | grep 'url:' | sed 's/[{}]//g' | sed -nr 's/.*url:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${GROUP_INTERVAL}" ]] && GROUP_INTERVAL=$( (sed 's/,/\n/g' | grep 'interval:' | sed 's/[{}]//g' | sed -nr 's/.*interval:\s*(.+)/\1/p') <<<"${READLINE}")
            [[ -z "${GROUP_TOLERANCE}" ]] && GROUP_TOLERANCE=$( (sed 's/,/\n/g' | grep 'tolerance:' | sed 's/[{}]//g' | sed -nr 's/.*tolerance:\s*(.+)/\1/p') <<<"${READLINE}")

            if grep -q "proxies:\s*\[" <<<"${READLINE}"; then
                GROUP_PROXIES=$(sed -nr 's/.*proxies:\s*\[(.+)\].*/\1/p' <<<"${READLINE}")
            else
                if grep -q "proxies:" <<<"${READLINE}"; then
                    GROUP_PROXIES_START="yes"
                    GROUP_PROXIES=""
                fi

                if [[ "${GROUP_PROXIES_START}" == "yes" ]]; then
                    GROUP_PROXY=$(sed -nr 's/\s*-\s*(.+)/\1/p' <<<"${READLINE}")
                    if [[ -n "${GROUP_PROXY}" ]]; then
                        [[ -n "${GROUP_PROXIES}" ]] && GROUP_PROXIES="${GROUP_PROXIES},${GROUP_PROXY}" || GROUP_PROXIES="${GROUP_PROXY}"
                    fi
                fi
            fi
            ;;
    esac
done < "${CONFIG_SRC}"

# last group
setProxyGroup

# Rule
colorEcho "${BLUE}  Processing ${FUCHSIA}[Rule]${BLUE}..."
echo '' | tee -a "${CONFIG_TO}" >/dev/null
echo '[Rule]' | tee -a "${CONFIG_TO}" >/dev/null

RULES_START_LINE=$(grep -Ean "^rules:" "${CONFIG_SRC}" | cut -d: -f1)
if [[ ${RULES_START_LINE} -gt 0 ]]; then
    RULES_FILE="${WORKDIR}/rules.yml"
    cp -f "${CONFIG_SRC}" "${RULES_FILE}"

    sed -i "1,${RULES_START_LINE} d" "${RULES_FILE}"
    sed -i '/^$/d' "${RULES_FILE}"
    sed -i 's/^\s*-\s*//g' "${RULES_FILE}"
    sed -i 's/MATCH,/FINAL,/g' "${RULES_FILE}"

    cat "${RULES_FILE}" >> "${CONFIG_TO}"
fi

colorEcho "${BLUE}Done!"
