#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

[[ -z "${MY_SHELL_SCRIPTS}" ]] && MY_SHELL_SCRIPTS="$HOME/.dotfiles"

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch
[[ -z "${OS_INFO_VDIS}" ]] && get_sysArch

# jq
if [[ ! -x "$(command -v jq)" ]]; then
    if checkPackageNeedInstall "jq"; then
        colorEcho "${BLUE}Installing ${FUCHSIA}jq${BLUE}..."
        sudo pacman --noconfirm -S jq
    fi
fi

if [[ ! -x "$(command -v jq)" ]]; then
    colorEcho "${FUCHSIA}jq${RED} is not installed!"
    exit 1
fi


# V2Ray Client
# https://www.v2ray.com/chapter_00/install.html
# service v2ray start|stop|status|reload|restart|force-reload
function install_v2ray_client() {
    [[ -s "${MY_SHELL_SCRIPTS}/cross/v2ray_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/cross/v2ray_installer.sh"
}

# Get v2ray config from subscriptions
function get_v2ray_config_from_subscription() {
    local SUBSCRIBE_URL=${1:-"https://jiang.netlify.com/"}
    local V2RAY_ADDRESS=${2:-"127.0.0.1:55880"}

    local VMESS_FILENAME="${WORKDIR}/v2ray.vmess"
    local DECODE_FILENAME="${WORKDIR}/v2ray_decode.vmess"
    local exitStatus=1

    colorEcho "${BLUE}  Getting v2ray subscriptions..."
    curl -fsL -4 --connect-timeout 10 --max-time 30 \
        -o "${VMESS_FILENAME}" "${SUBSCRIBE_URL}"

    curl_download_status=$?
    if [[ ${curl_download_status} != 0 ]]; then
        colorEcho "${RED}  Can't get the subscriptions from ${FUCHSIA}${SUBSCRIBE_URL}${RED}!"
        return 1
    fi

    if [[ -s "${VMESS_FILENAME}" ]]; then
        base64 -d "${VMESS_FILENAME}" > "${DECODE_FILENAME}"
        # sed -i -e '/^ss:\/\//d' -e '/^ssr:\/\//d' "${DECODE_FILENAME}"
        sed -i '/^vmess:\/\//!d' "${DECODE_FILENAME}"
        sed -i 's|^vmess://||g' "${DECODE_FILENAME}"
    fi

    if [[ ! -s "${DECODE_FILENAME}" ]]; then
        colorEcho "${RED}  Can't get the subscriptions from ${FUCHSIA}${SUBSCRIBE_URL}${RED}!"
        return 1
    fi

    colorEcho "${BLUE}  Testing v2ray config from subscriptions..."
    # Decode subscriptions line by line
    local V2RAY_PORT
    local READLINE
    local VMESS_CONFIG
    local VMESS_PS
    local VMESS_ADDR
    local VMESS_PORT
    local VMESS_USER_ID
    local VMESS_USER_ALTERID
    local VMESS_NETWORK
    local VMESS_TYPE
    local VMESS_SECURITY
    local VMESS_TLS_SETTINGS
    local VMESS_WS_HOST
    local VMESS_WS_PATH
    local VMESS_WS_SETTINGS
    local VMESS_KCP_SETTINGS

    V2RAY_PORT=$(echo "$V2RAY_ADDRESS" | cut -d":" -f2)

    while read -r READLINE; do
        [[ -z "${READLINE}" ]] && continue

        VMESS_CONFIG=$(echo "${READLINE}" | base64 -di)
        [[ -z "${VMESS_CONFIG}" ]] && continue

        VMESS_PS=$(echo "${VMESS_CONFIG}" | jq -r '.ps//empty')
        VMESS_ADDR=$(echo "${VMESS_CONFIG}" | jq -r '.add//empty')
        VMESS_PORT=$(echo "${VMESS_CONFIG}" | jq -r '.port//empty')
        [[ -z "${VMESS_ADDR}" || -z "${VMESS_PORT}" ]] && continue

        VMESS_USER_ID=$(echo "${VMESS_CONFIG}" | jq -r '.id//empty')
        VMESS_USER_ALTERID=$(echo "${VMESS_CONFIG}" | jq -r '.aid//empty')
        VMESS_NETWORK=$(echo "${VMESS_CONFIG}" | jq -r '.net//empty')
        VMESS_TYPE=$(echo "${VMESS_CONFIG}" | jq -r '.type//empty')
        VMESS_SECURITY=$(echo "${VMESS_CONFIG}" | jq -r '.tls//empty')
        VMESS_WS_HOST=$(echo "${VMESS_CONFIG}" | jq -r '.host//empty')
        VMESS_WS_PATH=$(echo "${VMESS_CONFIG}" | jq -r '.path//empty')

        colorEcho "${BLUE}  Testing ${VMESS_PS} ${VMESS_ADDR}:${VMESS_PORT}..."
        if [[ -z "${VMESS_SECURITY}" ]]; then
            VMESS_SECURITY="null"
        else
            VMESS_SECURITY="\"${VMESS_SECURITY}\""
        fi

        VMESS_TLS_SETTINGS="null"
        VMESS_WS_SETTINGS="null"
        VMESS_KCP_SETTINGS="null"

        if [[ "${VMESS_NETWORK}" == "ws" ]]; then
            if [[ -z "${VMESS_WS_PATH}" ]]; then
                VMESS_WS_PATH="null"
            else
                VMESS_WS_PATH="\"${VMESS_WS_PATH}\""
            fi

            if [[ -z "${VMESS_WS_HOST}" ]]; then
                VMESS_WS_HOST="null"
            else
                VMESS_WS_HOST="\"${VMESS_WS_HOST}\""
            fi

            VMESS_TLS_SETTINGS=$({ \
                    echo "{"; \
                    echo "                    \"allowInsecure\": false,"; \
                    echo "                    \"serverName\": ${VMESS_WS_HOST}"; \
                    echo "                }"; \
                })

            if [[ "${VMESS_WS_HOST}" == "null" ]]; then
                VMESS_WS_SETTINGS=$({ \
                        echo "{"; \
                        echo "                    \"connectionReuse\": true,"; \
                        echo "                    \"path\": ${VMESS_WS_PATH},"; \
                        echo "                    \"headers\": null"; \
                        echo "                }"; \
                    })
            else
                VMESS_WS_SETTINGS=$({ \
                        echo "{"; \
                        echo "                    \"connectionReuse\": true,"; \
                        echo "                    \"path\": ${VMESS_WS_PATH},"; \
                        echo "                    \"headers\": {"; \
                        echo "                        \"Host\": ${VMESS_WS_HOST}"; \
                        echo "                    }"; \
                        echo "                }"; \
                    })
            fi
        elif [[ "${VMESS_NETWORK}" == "kcp" ]]; then
            VMESS_KCP_SETTINGS=$({ \
                    echo "{"; \
                    echo "                    \"mtu\": 1350,"; \
                    echo "                    \"tti\": 50,"; \
                    echo "                    \"uplinkCapacity\": 12,"; \
                    echo "                    \"downlinkCapacity\": 100,"; \
                    echo "                    \"congestion\": false,"; \
                    echo "                    \"readBufferSize\": 2,"; \
                    echo "                    \"writeBufferSize\": 2,"; \
                    echo "                    \"headers\": {"; \
                    echo "                        \"type\": \"${VMESS_TYPE}\","; \
                    echo "                        \"request\": null,"; \
                    echo "                        \"response\": null"; \
                    echo "                    }"; \
                    echo "                }"; \
                })
        else
            continue
        fi

        # Gen config file
        # cat >/etc/v2ray/config.json <<-EOF
        sudo tee /etc/v2ray/config.json >/dev/null <<-EOF
{
    "inbounds": [{
            "tag": "proxy",
            "port": ${V2RAY_PORT},
            "listen": "0.0.0.0",
            "protocol": "socks",
            "sniffing": {
                "enabled": true,
                "destOverride": ["http", "tls"]
            },
            "settings": {
                "auth": "noauth",
                "udp": true,
                "ip": null,
                "address": null,
                "clients": null
            }
        }
    ],
    "outbounds": [{
            "tag": "proxy",
            "protocol": "vmess",
            "settings": {
                "vnext": [{
                    "address": "${VMESS_ADDR}",
                    "port": ${VMESS_PORT},
                    "users": [{
                        "id": "${VMESS_USER_ID}",
                        "alterId": ${VMESS_USER_ALTERID},
                        "email": "t@t.tt",
                        "security": "auto"
                    }]
                }]
            },
            "streamSettings": {
                "network": "${VMESS_NETWORK}",
                "security": ${VMESS_SECURITY},
                "tlsSettings": ${VMESS_TLS_SETTINGS},
                "tcpSettings": null,
                "kcpSettings": ${VMESS_KCP_SETTINGS},
                "wsSettings": ${VMESS_WS_SETTINGS},
                "httpSettings": null,
                "quicSettings": null
            },
            "mux": {
                "enabled": true
            }
        }
    ]
}
EOF

        # removed ^M
        sudo sed -i -e 's/'$(echo "\013")'//g' -e 's/\r//g' /etc/v2ray/config.json

        # check the config file
        if v2ray -test -config /etc/v2ray/config.json; then
            # restart v2ray client
            # service v2ray restart && sleep 1
            sudo systemctl restart v2ray && sleep 1

            # check the proxy work or not
            if check_socks5_proxy_up "${V2RAY_ADDRESS}"; then
                exitStatus=0
                break
            fi
        else
            break
        fi
    done < "${DECODE_FILENAME}"

    # rm -f ${VMESS_FILENAME} ${DECODE_FILENAME}

    if [ "$exitStatus" -eq "0" ]; then
        return 0
    else
        return 1
    fi
}

function use_v2ray() {
    local PROXY_URL=${1:-"127.0.0.1:55880"}
    local OS_INFO_WSL SubList SubListFile SubError

    OS_INFO_WSL=$(uname -r)
    if [[ "${OS_INFO_WSL}" =~ "Microsoft" || "${OS_INFO_WSL}" =~ "microsoft" ]]; then
        :
    else
        colorEcho "${BLUE}  Checking & loading v2ray proxy..."

        [[ ! -x "$(command -v v2ray)" ]] && install_v2ray_client

        SubListFile="${MY_SHELL_SCRIPTS}/cross/cross_gfw_subscription.list"
        if [[ -s "$SubListFile" ]]; then
            SubList=()
            while read -r READLINE || [[ "$READLINE" ]]; do
                SubList+=("$READLINE")
            done < "${SubListFile}"
        else
            SubList=(
                "https://jiang.netlify.com/"
            )
        fi

        if check_socks5_proxy_up "${PROXY_URL}"; then
            return 0
        else
            if [[ -x "$(command -v v2ray)" ]]; then
                SubError="yes"
                for TargetSub in "${SubList[@]}"; do
                    if get_v2ray_config_from_subscription "$TargetSub" "$PROXY_URL"; then
                        SubError="no"
                        break
                    fi
                done

                if [[ "$SubError" == "yes" ]]; then
                    colorEcho "${RED}  Something wrong when setup proxy ${FUCHSIA}${PROXY_URL}${RED}!"
                    return 1
                else
                    return 0
                fi
            fi
        fi
    fi

    return 1
}

# subconverter
# https://github.com/tindy2013/subconverter
function install_update_subconverter() {
    [[ -s "${MY_SHELL_SCRIPTS}/cross/subconverter_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/cross/subconverter_installer.sh"
}

# clash
# https://github.com/Dreamacro/clash
function install_update_clash() {
    [[ -s "${MY_SHELL_SCRIPTS}/cross/clash_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/cross/clash_installer.sh"
}

function use_clash() {
    local PROXY_URL=${1:-"127.0.0.1"}
    local SOCKS_PORT=${2:-"7891"}
    local MIXED_PORT=${3:-"7890"}
    local last_update="/srv/clash/.last_update"
    local SUB_CLASH_URL OS_INFO_WSL

    OS_INFO_WSL=$(uname -r)
    if [[ "${OS_INFO_WSL}" =~ "Microsoft" || "${OS_INFO_WSL}" =~ "microsoft" ]]; then
        :
    else
        colorEcho "${BLUE}  Checking & loading ${FUCHSIA}clash${BLUE} proxy..."

        [[ -s "/srv/subconverter/subconverter" ]] || install_update_subconverter
        [[ -s "/srv/subconverter/subconverter" ]] || {
                colorEcho "${RED}  Please install and run ${FUCHSIA}subconverter${RED} first!"
                return 1
            }

        [[ $(systemctl is-enabled subconverter 2>/dev/null) ]] || {
                Install_systemd_Service "subconverter" "/srv/subconverter/subconverter"
            }

        [[ -s "/srv/clash/clash" ]] || install_update_clash
        [[ -s "/srv/clash/clash" ]] || {
                colorEcho "${RED}  Please install and run ${FUCHSIA}clash${RED} first!"
                return 1
            }

        [[ $(systemctl is-enabled clash 2>/dev/null) ]] || {
                Install_systemd_Service "clash" "/srv/clash/clash -d /srv/clash"
            }

        if [[ $(systemctl is-enabled clash 2>/dev/null) ]]; then
            # # get clash config
            # [[ ! -s "$last_update" ]] && date -d "1 day ago" +"%F" > "$last_update"
            # # only update config one time per day
            # if [[ $(date -d $(date +"%F") +"%s") -gt $(date -d $(head -n1 "$last_update") +"%s") ]]; then
            #     [[ -s "${MY_SHELL_SCRIPTS}/cross/clash_client_config.sh" ]] && \
            #         bash "${MY_SHELL_SCRIPTS}/cross/clash_client_config.sh"
            #     sudo systemctl restart clash && sleep 3
            #     date +"%F" > "$last_update"
            # fi

            if check_socks5_proxy_up "${PROXY_URL}:${SOCKS_PORT}"; then
                return 0
            else
                if [[ -s "${MY_SHELL_SCRIPTS}/cross/clash_client_config.sh" ]]; then
                    bash "${MY_SHELL_SCRIPTS}/cross/clash_client_config.sh"
                    sudo systemctl restart clash && sleep 3
                fi
            fi

            if check_socks5_proxy_up "${PROXY_URL}:${SOCKS_PORT}"; then
                return 0
            else
                if [[ -s "${MY_SHELL_SCRIPTS}/cross/clash_client_subscribe.sh" ]]; then
                    # random subscription from list file
                    bash "${MY_SHELL_SCRIPTS}/cross/clash_client_subscribe.sh" 0
                    sudo systemctl restart clash && sleep 3
                fi
            fi

            if check_socks5_proxy_up "${PROXY_URL}:${SOCKS_PORT}"; then
                return 0
            else
                return 1
            fi
        fi
    fi
}

## main
function main() {
    local SOCKS_ADDRESS
    local PROXY_BY_V2RAY

    # Use proxy or mirror when some sites were blocked or low speed
    [[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

    # set global clash socks5 proxy or v2ray socks5 proxy
    if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
        colorEcho "${BLUE}Checking & loading proxy..."

        [[ -z "${GLOBAL_PROXY_IP}" ]] && use_clash 127.0.0.1 7891 7890

        if ! check_set_global_proxy 7891 7890; then
            colorEchoN "${ORANGE}Clash not working, use v2ray?[y/${CYAN}N${ORANGE}]: "
            read -r -t 5 PROXY_BY_V2RAY
            echo ""
            if [[ "$PROXY_BY_V2RAY" == "y" || "$PROXY_BY_V2RAY" == "Y" ]]; then
                SOCKS_ADDRESS="127.0.0.1:55880"
                if use_v2ray "${SOCKS_ADDRESS}"; then
                    set_special_socks5_proxy "${SOCKS_ADDRESS}"
                    set_git_special_proxy "github.com,gitlab.com" "socks5://${SOCKS_ADDRESS}"
                    colorEcho "${GREEN}  Socks5 proxy address: ${FUCHSIA}${SOCKS_ADDRESS}"
                else
                    set_special_socks5_proxy
                    set_git_special_proxy "github.com,gitlab.com"
                fi
            fi
        fi
    fi
}


main