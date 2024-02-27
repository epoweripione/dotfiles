#!/usr/bin/env bash

## curl to check webservice is up
# https://stackoverflow.com/questions/12747929/linux-script-with-curl-to-check-webservice-is-up
function check_webservice_up() {
    # How to use:
    # if check_webservice_up www.google.com; then echo "ok"; else echo "something wrong"; fi
    local webservice_url=${1:-"www.google.com"}
    local http exitStatus=0

    http=$(curl -fsL --noproxy "*" --connect-timeout 3 --max-time 5 \
        -w "%{http_code}\\n" "${webservice_url}" -o /dev/null)
    case "${http}" in
        [2]*)
            ;;
        [3]*)
            # echo "${webservice_url} is REDIRECT with ${http}"
            ;;
        [4]*)
            exitStatus=4
            # echo "${webservice_url} is DENIED with ${http}"
            ;;
        [5]*)
            exitStatus=5
            # echo "${webservice_url} is ERROR with ${http}"
            ;;
        *)
            exitStatus=6
            # echo "${webservice_url} is NO RESPONSE with ${http}"
            ;;
    esac

    if [[ "${exitStatus}" -eq "0" ]]; then
        # echo "${webservice_url} is UP with ${http}"
        return 0
    else
        return 1
    fi
}

# Verify if a URL exists
function check_url_exists() {
    local url=$1
    local http exitStatus=0

    http=$(curl -fsL -I --connect-timeout 3 --max-time 5 \
        -w "%{http_code}\n" "${url}" -o /dev/null)
    case "${http}" in
        [2]*)
            ;;
        [3]*)
            # echo "${url} is REDIRECT with ${http}"
            ;;
        [4]*)
            exitStatus=4
            # echo "${url} is DENIED with ${http}"
            ;;
        [5]*)
            exitStatus=5
            # echo "${url} is ERROR with ${http}"
            ;;
        *)
            exitStatus=6
            # echo "${url} is NO RESPONSE with ${http}"
            ;;
    esac

    if [[ "${exitStatus}" -eq "0" ]]; then
        # echo "${webservice_url} is UP with ${http}"
        return 0
    else
        return 1
    fi
}

## curl to check webservice timeout
# https://stackoverflow.com/questions/18215389/how-do-i-measure-request-and-response-times-at-once-using-curl
#     time_namelookup:  %{time_namelookup}\n
#        time_connect:  %{time_connect}\n
#     time_appconnect:  %{time_appconnect}\n
#    time_pretransfer:  %{time_pretransfer}\n
#       time_redirect:  %{time_redirect}\n
#  time_starttransfer:  %{time_starttransfer}\n
#                     ----------\n
#          time_total:  %{time_total}\n
function check_webservice_timeout() {
    local webservice_url=${1:-"www.google.com"}
    local http_timeout

    http_timeout=$(curl -fsL --connect-timeout 5 --max-time 20 \
        -w "%{time_connect} + %{time_starttransfer} = %{time_total}\\n" \
        "${webservice_url}" -o /dev/null)

    echo "time_connect + time_starttransfer: ${http_timeout}"
}

## Get network interface, ipv4/ipv6 address
# Get local machine network interfaces
function get_network_interface_list() {
    unset NETWORK_INTERFACE_LIST

    if [[ -x "$(command -v ip)" ]]; then
        NETWORK_INTERFACE_LIST=$(ip route 2>/dev/null | sed -e "s/^.*dev.//" | awk '{print $1}' | uniq)
        # Without wireless
        # NETWORK_INTERFACE_LIST=$(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]" {print $2;getline}')
        if [[ -z "${NETWORK_INTERFACE_LIST}" ]]; then
            NETWORK_INTERFACE_LIST=$(ip link 2>/dev/null | awk -F: '$0 !~ "lo|vir|^[^0-9]" {print $2;getline}')
        fi
    else
        NETWORK_INTERFACE_LIST=$(ls /sys/class/net 2>/dev/null | tr "\t" "\n" | grep -Ev "lo|vir|^[0-9]")
    fi
}

function get_network_interface_default() {
    unset NETWORK_INTERFACE_DEFAULT

    if [[ -x "$(command -v ip)" ]]; then
        NETWORK_INTERFACE_DEFAULT=$(ip route 2>/dev/null | grep default | sed -e "s/^.*dev.//" | awk '{print $1}' | head -n1)
        if [[ -z "${NETWORK_INTERFACE_DEFAULT}" ]]; then
            NETWORK_INTERFACE_DEFAULT=$(ip route 2>/dev/null | grep -Ev "^0\.|^127\.|^172\." | sed -e "s/^.*dev.//" | awk '{print $1}' | head -n1)
        fi
    elif [[ -x "$(command -v netstat)" ]]; then
        NETWORK_INTERFACE_DEFAULT=$(netstat -rn 2>/dev/null | awk '/^0.0.0.0/ {thif=substr($0,74,10); print thif;} /^default.*UG/ {thif=substr($0,65,10); print thif;}')
    fi
}

function get_network_wireless_interface_list() {
    local wireless_dev

    unset NETWORK_WIRELESS_INTERFACE_LIST

    if [[ -x "$(command -v iw)" ]]; then
        NETWORK_WIRELESS_INTERFACE_LIST=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}')
    else
        for wireless_dev in /sys/class/net/*; do
            if [[ -e "${wireless_dev}"/wireless ]]; then
                if [[ -z "${NETWORK_WIRELESS_INTERFACE_LIST}" ]]; then
                    NETWORK_WIRELESS_INTERFACE_LIST="${wireless_dev##*/}"
                else
                    NETWORK_WIRELESS_INTERFACE_LIST="${NETWORK_WIRELESS_INTERFACE_LIST}\n${wireless_dev##*/}"
                fi
            fi
        done
    fi
}

# get local machine ip list
function get_network_local_ip_list() {
    unset NETWORK_LOCAL_IP_LIST

    get_network_interface_list
    [[ -z "$NETWORK_INTERFACE_LIST" ]] && return 0

    local net_interface_list net_interface net_ip list

    # net_interface_list=($(echo "$NETWORK_INTERFACE_LIST" | tr '\n' ' '))
    net_interface_list=()
    while read -r list; do
        net_interface_list+=("${list}")
    done <<<"${NETWORK_INTERFACE_LIST}"

    for net_interface in "${net_interface_list[@]}"; do
        if [[ -x "$(command -v ip)" ]]; then
            net_ip=$(ip addr show "${net_interface}" 2>/dev/null | grep "inet\|inet6" | awk '{print $2}' | cut -d'/' -f1)
        elif [[ -x "$(command -v ifconfig)" ]]; then
            net_ip=$(ifconfig "${net_interface}" 2>/dev/null | grep "inet\|inet6" |awk -F' ' '{print $2}' | awk '{print $1}')
        fi

        if [[ -n "${net_ip}" ]]; then
            net_ip=$(echo "${net_ip}" | grep -v "127.0.0.1" | grep -v "^::1" | grep -v "^fe80")
        fi

        [[ -z "${net_ip}" ]] && continue
        # net_ip="${net_interface}: ${net_ip}"

        [[ -z "$NETWORK_LOCAL_IP_LIST" ]] \
            && NETWORK_LOCAL_IP_LIST="${net_ip}" \
            || NETWORK_LOCAL_IP_LIST="${NETWORK_LOCAL_IP_LIST}\n${net_ip}"
    done
}

function get_network_local_ipv4_list() {
    unset NETWORK_LOCAL_IPV4_LIST

    get_network_local_ip_list
    [[ -z "$NETWORK_LOCAL_IP_LIST" ]] && return 0

    NETWORK_LOCAL_IPV4_LIST=$(echo "$NETWORK_LOCAL_IP_LIST" | grep -B1 "\.")

    NETWORK_LOCAL_IPV4_LIST=${NETWORK_LOCAL_IPV4_LIST//-/}
}

function get_network_local_ipv6_list() {
    unset NETWORK_LOCAL_IPV6_LIST

    get_network_local_ip_list
    [[ -z "$NETWORK_LOCAL_IP_LIST" ]] && return 0

    NETWORK_LOCAL_IPV6_LIST=$(echo "$NETWORK_LOCAL_IP_LIST" | grep -v "\.")
}


# get local machine default interface ip
function get_network_local_ip_default() {
    unset NETWORK_LOCAL_IP_DEFAULT

    get_network_interface_default
    [[ -z "$NETWORK_INTERFACE_DEFAULT" ]] && return 0

    local net_ip

    if [[ -x "$(command -v ip)" ]]; then
        net_ip=$(ip addr show "${NETWORK_INTERFACE_DEFAULT}" 2>/dev/null | grep "inet\|inet6" | awk '{print $2}' | cut -d'/' -f1)
    elif [[ -x "$(command -v ifconfig)" ]]; then
        net_ip=$(ifconfig "${NETWORK_INTERFACE_DEFAULT}" 2>/dev/null | grep "inet\|inet6" |awk -F' ' '{print $2}' | awk '{print $1}')
    fi

    NETWORK_LOCAL_IP_DEFAULT="${net_ip}"
}

function get_network_local_ipv4_default() {
    # https://stackoverflow.com/questions/13322485/how-to-get-the-primary-ip-address-of-the-local-machine-on-linux-and-os-x
    # LOCAL_NET_IF=$(netstat -rn | awk '/^0.0.0.0/ {thif=substr($0,74,10); print thif;} /^default.*UG/ {thif=substr($0,65,10); print thif;}')
    # LOCAL_NET_IP=$(ifconfig ${LOCAL_NET_IF} | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

    unset NETWORK_LOCAL_IPV4_DEFAULT

    get_network_local_ip_default
    [[ -z "$NETWORK_LOCAL_IP_DEFAULT" ]] && return 0

    NETWORK_LOCAL_IPV4_DEFAULT=$(echo "$NETWORK_LOCAL_IP_DEFAULT" | grep "\." | head -n1)
}

function get_network_local_ipv6_default() {
    unset NETWORK_LOCAL_IPV6_DEFAULT

    get_network_local_ip_default
    [[ -z "$NETWORK_LOCAL_IP_DEFAULT" ]] && return 0

    NETWORK_LOCAL_IPV6_DEFAULT=$(echo "$NETWORK_LOCAL_IP_DEFAULT" | grep ":" | head -n1)
}

# get wan ip
function get_network_wan_ipv4() {
    # https://guoyu841020.oschina.io/2017/02/23/linux%E8%8E%B7%E5%8F%96%E5%85%AC%E7%BD%91IP%E7%9A%84%E6%96%B9%E6%B3%95/
    # nginx:
    # https://www.jianshu.com/p/14320f300223
    # location /ip {
    #         default_type text/plain;
    #         return 200 "$remote_addr";
    # }

    # location /ipinfo {
    #         default_type application/json;
    #         return 200  '{"IP":"$remote_addr","PORT":"$remote_port","X-Forwarded-For":"$proxy_add_x_forwarded_for"}';
    # }
    # php:
    # <?php echo $_SERVER["REMOTE_ADDR"]; ?>
    # pacman -S --noconfirm html2text
    # curl -fsSL http://yourdomainname/getip.php | html2text
    # nodejs:
    # https://github.com/alsotang/externalip
    # https://github.com/sindresorhus/public-ip
    unset NETWORK_WAN_NET_IP

    local remote_host_list target_host

    remote_host_list=(
        # "http://ip-api.com/line/?fields=query"
        "https://v4.ident.me/"
        "http://icanhazip.com/"
        "http://ipinfo.io/ip"
        "https://ifconfig.co/"
        "https://api-ipv4.ip.sb/ip"
    )

    for target_host in "${remote_host_list[@]}"; do
        NETWORK_WAN_NET_IP=$(curl -fsL -4 --noproxy "*" --connect-timeout 5 --max-time 10 "${target_host}" \
                        | grep -Eo '([0-9]{1,3}[\.]){3}[0-9]{1,3}' \
                        | head -n1)
        [[ -n "$NETWORK_WAN_NET_IP" ]] && break
    done
    # NETWORK_WAN_NET_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
}

function get_network_wan_ipv6() {
    unset NETWORK_WAN_NET_IPV6

    local remote_host_list target_host

    remote_host_list=(
        "https://v6.ident.me/"
        "http://icanhazip.com/"
        "https://ifconfig.co/"
        "https://api-ipv6.ip.sb/ip"
    )

    for target_host in "${remote_host_list[@]}"; do
        NETWORK_WAN_NET_IPV6=$(curl -fsL -6 --noproxy "*" --connect-timeout 5 --max-time 10 "${target_host}" \
                        | grep -Eo '^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$' \
                        | head -n1)
        [[ -n "$NETWORK_WAN_NET_IPV6" ]] && break
    done
}

function get_network_wan_geo() {
    unset NETWORK_WAN_NET_IP_GEO

    if [[ -x "$(command -v geoiplookup)" ]]; then
        get_network_wan_ipv4
        if [[ -n "$NETWORK_WAN_NET_IP" ]]; then
            NETWORK_WAN_NET_IP_GEO=$(geoiplookup "${NETWORK_WAN_NET_IP}" | head -n1 | cut -d':' -f2-)
        fi
    fi

    if [[ -z "$NETWORK_WAN_NET_IP_GEO" ]]; then
        NETWORK_WAN_NET_IP_GEO=$(curl -fsL -4 --noproxy "*" --connect-timeout 5 --max-time 10 --user-agent Mozilla \
            "https://api.ip.sb/geoip" | jq -r '.country//empty')
    fi

    if [[ -z "$NETWORK_WAN_NET_IP_GEO" ]]; then
        # Country lookup: China
        NETWORK_WAN_NET_IP_GEO=$(curl -fsL -4 --noproxy "*" --connect-timeout 5 --max-time 10 \
            "https://ifconfig.co/country")
    fi

    if [[ -z "$NETWORK_WAN_NET_IP_GEO" ]]; then
        # Country lookup: CN
        NETWORK_WAN_NET_IP_GEO=$(curl -fsL -4 --noproxy "*" --connect-timeout 5 --max-time 10 \
            "https://ipinfo.io/country")
    fi
}

function get_network_wan_geo_city() {
    unset NETWORK_WAN_NET_IP_CITY

    if [[ -z "$NETWORK_WAN_NET_IP_CITY" ]]; then
        NETWORK_WAN_NET_IP_CITY=$(curl -fsL -4 --noproxy "*" --connect-timeout 5 --max-time 10 --user-agent Mozilla \
            "https://api.ip.sb/geoip" | jq -r '.city//empty')
    fi

    if [[ -z "$NETWORK_WAN_NET_IP_CITY" ]]; then
        NETWORK_WAN_NET_IP_CITY=$(curl -fsL -4 --noproxy "*" --connect-timeout 5 --max-time 10 \
            "https://ifconfig.co/city")
    fi

    if [[ -z "$NETWORK_WAN_NET_IP_CITY" ]]; then
        NETWORK_WAN_NET_IP_CITY=$(curl -fsL -4 --noproxy "*" --connect-timeout 5 --max-time 10 \
            "https://ipinfo.io/city")
    fi
}

# display local machine ip info
function myip_lan_wan() {
    get_network_local_ipv4_default
    get_network_local_ipv6_default
    get_network_wan_ipv4
    get_network_wan_ipv6

    [[ -n "$NETWORK_LOCAL_IPV4_DEFAULT" ]] && echo -e "Local IP: ${NETWORK_LOCAL_IPV4_DEFAULT}"
    [[ -n "$NETWORK_LOCAL_IPV6_DEFAULT" ]] && echo -e "Local IPV6: ${NETWORK_LOCAL_IPV6_DEFAULT}"
    [[ -n "$NETWORK_WAN_NET_IP" ]] && echo -e "Public IP: ${NETWORK_WAN_NET_IP}"
    [[ -n "$NETWORK_WAN_NET_IPV6" ]] && echo -e "Public IPV6: ${NETWORK_WAN_NET_IPV6}"
}

function myip_lan() {
    get_network_local_ipv4_default
    get_network_local_ipv6_default

    [[ -n "$NETWORK_LOCAL_IPV4_DEFAULT" ]] && echo -e "Local IP: ${NETWORK_LOCAL_IPV4_DEFAULT}"
    [[ -n "$NETWORK_LOCAL_IPV6_DEFAULT" ]] && echo -e "Local IPV6: ${NETWORK_LOCAL_IPV6_DEFAULT}"
}

function myip_wan() {
    get_network_wan_ipv4
    get_network_wan_ipv6

    [[ -n "$NETWORK_WAN_NET_IP" ]] && echo -e "Public IP: ${NETWORK_WAN_NET_IP}"
    [[ -n "$NETWORK_WAN_NET_IPV6" ]] && echo -e "Public IPV6: ${NETWORK_WAN_NET_IPV6}"
}

function myip_wan_geo() {
    get_network_wan_ipv4
    get_network_wan_geo

    if [[ -n "$NETWORK_WAN_NET_IP_GEO" ]]; then
        echo -e "Public IP: ${NETWORK_WAN_NET_IP}\n${NETWORK_WAN_NET_IP_GEO}"
    else
        echo "Can't get GEO by WAN IP!"
    fi
}

# Get Opened Port on Android Device(No Root)
# https://null-byte.wonderhowto.com/forum/see-your-opened-port-your-android-device-no-root-0200475/
function nmap_scan_opened_port() {
    local ip_address=${1:-""}

    [[ -z "${ip_address}" ]] && get_network_local_ipv4_default && ip_address=${NETWORK_LOCAL_IPV4_DEFAULT}
    [[ -n "${ip_address}" ]] && nmap -Pn "${ip_address}"
}

## Flush dns cache
function flush_dns_cache() {
    [[ -s "/lib/systemd/system/systemd-resolved.service" ]] && \
        sudo ln -sf /lib/systemd/system/systemd-resolved.service \
            /etc/systemd/system/dbus-org.freedesktop.resolve1.service || true

    [[ -x "$(command -v systemd-resolve)" ]] && \
        sudo systemd-resolve --flush-caches >/dev/null 2>&1

    [[ -s "/etc/init.d/dns-clean" ]] && /etc/init.d/dns-clean start

    if systemctl is-enabled systemd-resolved >/dev/null 2>&1; then
        sudo systemctl restart systemd-resolved.service >/dev/null 2>&1
    fi

    if systemctl is-enabled dnsmasq >/dev/null 2>&1; then
        sudo systemctl restart dnsmasq.service >/dev/null 2>&1
    fi
}

## Download hosts from url
function download_hosts() {
    local hostsURL=${1:-""}
    local hostsFile=${2:-"/etc/hosts"}
    local exitStatus=0

    [[ -z "$hostsURL" ]] && return 1

    colorEcho "${BLUE}Downloading hosts from ${hostsURL}..."
    curl -fSL --connect-timeout 5 --max-time 20 \
        -o "/tmp/hosts" "$hostsURL" || exitStatus=$?
    if [[ "$exitStatus" -eq "0" ]]; then
        if [[ "${hostsFile}" == "/etc/hosts" ]]; then
            [[ ! -s "${hostsFile}.orig" ]] && \
                sudo cp -f "${hostsFile}" "${hostsFile}.orig"

            sudo cp -f "${hostsFile}" "${hostsFile}.bak" && \
                sudo mv -f "/tmp/hosts" "${hostsFile}" && \
                flush_dns_cache
        else
            cp -f "${hostsFile}" "${hostsFile}.bak" && \
                mv -f "/tmp/hosts" "${hostsFile}"
        fi

        return 0
    else
        return 1
    fi
}

function reset_hosts() {
    local hostsFile=${1:-"/etc/hosts"}

    [[ -s "${hostsFile}.orig" ]] && \
        sudo cp -f "${hostsFile}.orig" "${hostsFile}"
}
