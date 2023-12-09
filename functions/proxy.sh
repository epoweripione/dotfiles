#!/usr/bin/env bash

# Proxy functions
function get_no_proxy() {
    # hostname & hostip
    [[ -z "${HOSTNAME}" ]] && HOSTNAME=$(uname -n 2>/dev/null)
    [[ -z "${HOSTNAME}" ]] && HOSTNAME=$(hostname 2>/dev/null)
    [[ -n "${HOSTNAME}" ]] && export HOSTNAME

    [[ -z "${HOSTIP}" ]] && HOSTIP=$(hostname -I 2>/dev/null | cut -d' ' -f1)
    [[ -n "${HOSTIP}" ]] && export HOSTIP

    [[ -z "${HOSTIP_ALL}" ]] && HOSTIP_ALL=$(hostname -I 2>/dev/null)
    [[ -n "${HOSTIP_ALL}" ]] && HOSTIP_ALL="${HOSTIP_ALL% }" && HOSTIP_ALL="${HOSTIP_ALL// /,}" && export HOSTIP_ALL

    # no proxy lists
    if [[ -z "${NO_PROXY_LIST[*]}" ]]; then
        NO_PROXY_LIST=(
            "127.0.0.1"
            "::1"
            ".corp"
            ".internal"
            ".local"
            ".localdomain"
        )
    fi
    for Target in "${NO_PROXY_LIST[@]}"; do
        [[ -n "${GLOBAL_NO_PROXY}" ]] && GLOBAL_NO_PROXY="${GLOBAL_NO_PROXY},${Target}" || GLOBAL_NO_PROXY="${Target}"
    done

    [[ -n "${HOSTNAME}" ]] && GLOBAL_NO_PROXY="${GLOBAL_NO_PROXY},${HOSTNAME}"
    [[ -n "${HOSTIP_ALL}" ]] && GLOBAL_NO_PROXY="${GLOBAL_NO_PROXY},${HOSTIP_ALL}"

    export GLOBAL_NO_PROXY="${GLOBAL_NO_PROXY}"
}

function set_proxy() {
    # PROTOCOL://USERNAME:PASSWORD@HOST:PORT
    # http://127.0.0.1:8080
    # socks5h://127.0.0.1:8080
    # PASSWORD has special characters:
    # [@ %40] [: %3A] [! %21] [# %23] [$ %24]
    # F@o:o!B#ar$ -> F%40o%3Ao%21B%23ar%24
    local PROXY_ADDRESS=${1:-""}

    if [[ -z "${PROXY_ADDRESS}" && -n "${GLOBAL_PROXY_IP}" ]]; then
        if [[ -n "${GLOBAL_PROXY_SOCKS_PORT}" ]]; then
            PROXY_ADDRESS="${GLOBAL_PROXY_SOCKS_PROTOCOL}://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_SOCKS_PORT}"
        elif [[ -n "${GLOBAL_PROXY_MIXED_PORT}" ]]; then
            PROXY_ADDRESS="http://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}"
        fi
    fi

    [[ -z "${PROXY_ADDRESS}" ]] && PROXY_ADDRESS="http://127.0.0.1:8080"

    export {http,https,ftp,all}_proxy="${PROXY_ADDRESS}"
    export no_proxy="${GLOBAL_NO_PROXY}"
    # export no_proxy="localhost,127.0.0.0/8,*.local"

    # for curl
    export {HTTP,HTTPS,FTP,ALL}_PROXY="${PROXY_ADDRESS}"
    export NO_PROXY="${GLOBAL_NO_PROXY}"
}

function get_proxy() {
    local proxy_output1 proxy_output2

    [[ -n "${http_proxy}" ]] && colorEcho "${BLUE}http_proxy=${FUCHSIA}${http_proxy}"
    [[ -n "${https_proxy}" ]] && colorEcho "${BLUE}https_proxy=${FUCHSIA}${https_proxy}"
    [[ -n "${ftp_proxy}" ]] && colorEcho "${BLUE}ftp_proxy=${FUCHSIA}${ftp_proxy}"
    [[ -n "${all_proxy}" ]] && colorEcho "${BLUE}all_proxy=${FUCHSIA}${all_proxy}"
    [[ -n "${no_proxy}" ]] && colorEcho "${BLUE}no_proxy=${FUCHSIA}${no_proxy}"

    echo ""
    [[ -n "${HTTP_PROXY}" ]] && colorEcho "${BLUE}HTTP_PROXY=${FUCHSIA}${HTTP_PROXY}"
    [[ -n "${HTTPS_PROXY}" ]] && colorEcho "${BLUE}HTTPS_PROXY=${FUCHSIA}${HTTPS_PROXY}"
    [[ -n "${FTP_PROXY}" ]] && colorEcho "${BLUE}FTP_PROXY=${FUCHSIA}${FTP_PROXY}"
    [[ -n "${ALL_PROXY}" ]] && colorEcho "${BLUE}ALL_PROXY=${FUCHSIA}${ALL_PROXY}"
    [[ -n "${NO_PROXY}" ]] && colorEcho "${BLUE}NO_PROXY=${FUCHSIA}${NO_PROXY}"

    if [[ -x "$(command -v git)" ]]; then
        proxy_output1=$(git config --global --list 2>/dev/null | grep -E "http\.proxy|https\.proxy|http\.http|https\.http")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}git proxies:\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -x "$(command -v node)" && -x "$(command -v npm)" ]]; then
        proxy_output1=$(npm config get proxy | grep -v "null")
        proxy_output2=$(npm config get https-proxy | grep -v "null")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}npm proxies:\n${FUCHSIA}${proxy_output1}"
        [[ -n "${proxy_output2}" ]] && colorEcho "${FUCHSIA}${proxy_output2}"
    fi

    if [[ -x "$(command -v yarn)" ]]; then
        proxy_output1=$(yarn config get proxy | grep -Ev "null|undefined")
        proxy_output2=$(yarn config get https-proxy | grep -Ev "null|undefined")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}yarn proxies:\n${FUCHSIA}${proxy_output1}"
        [[ -n "${proxy_output2}" ]] && colorEcho "${FUCHSIA}${proxy_output2}"
    fi

    if [[ -s "/etc/apt/apt.conf.d/80proxy" ]]; then
        proxy_output1=$(< "/etc/apt/apt.conf.d/80proxy")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}apt proxies:\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -s "/etc/yum.conf" ]]; then
        proxy_output1=$(grep "proxy=" "/etc/yum.conf")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}yum proxies:\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -s "$HOME/.wgetrc" ]]; then
        proxy_output1=$(< "$HOME/.wgetrc")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}wget proxies:\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -s "$HOME/.curlrc" ]]; then
        proxy_output1=$(< "$HOME/.curlrc")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}curl proxies(.curlrc):\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -s "$HOME/.curl_socks5" ]]; then
        proxy_output1=$(< "$HOME/.curl_socks5")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}curl proxies(.curl_socks5):\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -s "$HOME/.gradle/gradle.properties" ]]; then
        proxy_output1=$(grep "systemProp.http" "$HOME/.gradle/gradle.properties")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}gradle proxies:\n${FUCHSIA}${proxy_output1}"
    fi

    if [[ -s "$HOME/.gemrc" ]]; then
        proxy_output1=$(grep "http_proxy: " "$HOME/.gemrc")
        [[ -n "${proxy_output1}" ]] && colorEcho "\n${BLUE}gem proxies:\n${FUCHSIA}${proxy_output1}"
    fi
}

function clear_proxy() {
    unset {http,https,ftp,all}_proxy
    unset {HTTP,HTTPS,FTP,ALL}_PROXY
}

function clear_all_proxy() {
    clear_proxy
    set_git_proxy
    # set_git_special_proxy "github.com,gitlab.com"
    set_curl_socks_proxy
    # [[ -s "$HOME/.curl_socks5" ]] && set_curl_socks_proxy "" "$HOME/.curl_socks5"
    set_special_socks5_proxy
    set_wget_proxy
}

function proxy_cmd() {
    [[ -z $* ]] && colorEcho "${GREEN}Set proxy for specific command." && return 0

    if [[ -n "${all_proxy}" ]]; then
        colorEcho "${GREEN}Using proxy: ${FUCHSIA}${all_proxy}"
        "$@"
    else
        if [[ -n "${GLOBAL_PROXY_IP}" ]]; then
            if [[ -n "${GLOBAL_PROXY_SOCKS_PORT}" ]]; then
                set_proxy "${GLOBAL_PROXY_SOCKS_PROTOCOL}://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_SOCKS_PORT}"
            elif [[ -n "${GLOBAL_PROXY_MIXED_PORT}" ]]; then
                set_proxy "http://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}"
            fi
        fi

        [[ -n "${all_proxy}" ]] && colorEcho "${GREEN}Using proxy: ${FUCHSIA}${all_proxy}"
        "$@"
        [[ -n "${all_proxy}" ]] && clear_proxy && colorEcho "${GREEN}Proxy clear."
    fi
}

function proxy_http_cmd() {
    local proxy_address

    [[ -z $* ]] && colorEcho "${GREEN}No proxy for specific command." && return 0

    if [[ -n "${GLOBAL_PROXY_MIXED_PORT}" ]]; then
        proxy_address="http://${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}"
        http_proxy="${proxy_address}" https_proxy="${proxy_address}" \
            ftp_proxy="${proxy_address}" all_proxy="${proxy_address}" \
            HTTP_PROXY="${proxy_address}" HTTPS_PROXY="${proxy_address}" \
            FTP_PROXY="${proxy_address}" ALL_PROXY="${proxy_address}" \
            "$@"
    else
        "$@"
    fi
}

function noproxy_cmd() {
    [[ -z $* ]] && colorEcho "${GREEN}No proxy for specific command." && return 0

    if [[ -n "${all_proxy}" ]]; then
        http_proxy="" https_proxy="" ftp_proxy="" all_proxy="" \
            HTTP_PROXY="" HTTPS_PROXY="" FTP_PROXY="" ALL_PROXY="" \
            "$@"
    else
        "$@"
    fi
}

function proxy_socks5h_to_socks5() {
    # fix: golang - proxyconnect tcp: dial tcp: lookup socks5h: no such host
    # https://github.com/golang/go/issues/13454
    # https://github.com/golang/go/issues/24135
    [[ -z $* ]] && colorEcho "${GREEN}Use ${FUCHSIA}socks5${GREEN} proxy instead of ${BLUE}socks5h${GREEN} for specific command." && return 0

    if echo "${all_proxy}" | grep -q 'socks5h'; then
        colorEcho "${GREEN}Using proxy: ${FUCHSIA}${all_proxy/socks5h/socks5}"
        http_proxy=${http_proxy/socks5h/socks5} \
            https_proxy=${https_proxy/socks5h/socks5} \
            ftp_proxy=${ftp_proxy/socks5h/socks5} \
            all_proxy=${all_proxy/socks5h/socks5} \
            HTTP_PROXY=${HTTP_PROXY/socks5h/socks5} \
            HTTPS_PROXY=${HTTPS_PROXY/socks5h/socks5} \
            FTP_PROXY=${FTP_PROXY/socks5h/socks5} \
            ALL_PROXY=${ALL_PROXY/socks5h/socks5} \
            "$@"
    else
        [[ -n "${all_proxy}" ]] && colorEcho "${GREEN}Using proxy: ${FUCHSIA}${all_proxy}"
        "$@"
    fi
}

# SET_PROXY_FOR=('brew' 'git' 'apm')
# for cmd in $SET_PROXY_FOR; do
#     hash ${cmd} > /dev/null 2>&1 && alias ${cmd}="proxy_cmd ${cmd}"
# done

# Use proxy or mirror when some sites were blocked or low speed
function set_proxy_mirrors_env() {
    if check_webservice_up www.google.com; then
        export THE_WORLD_BLOCKED=false
    else
        export THE_WORLD_BLOCKED=true
    fi
}

# test the availability of a socks5 proxy
function check_socks5_proxy_up() {
    # How to use:
    # if check_socks5_proxy_up 127.0.0.1:1080 www.google.com; then echo "ok"; else echo "something wrong"; fi
    local PROXY_ADDRESS=${1:-""}
    local webservice_url=${2:-"www.google.com"}
    local exitStatus=0

    if [[ -z "${PROXY_ADDRESS}" && -n "${GLOBAL_PROXY_IP}" && -n "${GLOBAL_PROXY_SOCKS_PORT}" ]]; then
        PROXY_ADDRESS="${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_SOCKS_PORT}"
    fi

    [[ -z "${PROXY_ADDRESS}" ]] && PROXY_ADDRESS="127.0.0.1:1080"

    curl -fsL -I --connect-timeout 3 --max-time 5 \
        --socks5-hostname "${PROXY_ADDRESS}" \
        "${webservice_url}" >/dev/null 2>&1 || exitStatus=$?

    if [[ "$exitStatus" -eq "0" ]]; then
        return 0
    else
        return 1
    fi
}

# test the availability of a http proxy
function check_http_proxy_up() {
    # How to use:
    # if check_http_proxy_up 127.0.0.1:8080 www.google.com; then echo "ok"; else echo "something wrong"; fi
    local PROXY_ADDRESS=${1:-""}
    local webservice_url=${2:-"www.google.com"}
    local exitStatus=0

    if [[ -z "${PROXY_ADDRESS}" && -n "${GLOBAL_PROXY_IP}" && -n "${GLOBAL_PROXY_MIXED_PORT}" ]]; then
        PROXY_ADDRESS="${GLOBAL_PROXY_IP}:${GLOBAL_PROXY_MIXED_PORT}"
    fi

    [[ -z "${PROXY_ADDRESS}" ]] && PROXY_ADDRESS="127.0.0.1:8080"

    curl -fsL -I --connect-timeout 3 --max-time 5 \
        --proxy "${PROXY_ADDRESS}" \
        "${webservice_url}" >/dev/null 2>&1 || exitStatus=$?

    if [[ "$exitStatus" -eq "0" ]]; then
        return 0
    else
        return 1
    fi
}

# Set global git proxy
function set_git_proxy() {
    local PROXY_ADDRESS=$1

    if [[ -z "$PROXY_ADDRESS" ]]; then
        git config --global --unset http.proxy
        git config --global --unset https.proxy
    else
        git config --global http.proxy "${PROXY_ADDRESS}"
        git config --global https.proxy "${PROXY_ADDRESS}"
    fi
}

# Set socks5 proxy for certain git repos
function set_git_special_proxy() {
    # Usage: set_git_special_proxy github.com,gitlab.com 127.0.0.1:55880
    local GIT_REPO_LIST=$1
    local PROXY_ADDRESS=${2:-""}
    local Url_List=() TargetUrl list

    # Url_List=($(echo "${GIT_REPO_LIST}" | sed 's/,/ /g'))
    while read -r list; do
        Url_List+=("${list}")
    done <<<"${GIT_REPO_LIST}"

    for TargetUrl in "${Url_List[@]}"; do
        [[ -z "${TargetUrl}" ]] && continue

        if [[ -z "$PROXY_ADDRESS" ]]; then
            git config --global --unset "http.https://${TargetUrl}.proxy"
            git config --global --unset "https.https://${TargetUrl}.proxy"
        else
            git config --global "http.https://${TargetUrl}.proxy" "${PROXY_ADDRESS}"
            git config --global "https.https://${TargetUrl}.proxy" "${PROXY_ADDRESS}"
        fi
    done
}

# Set apt proxy
function set_apt_proxy() {
    local PROXY_ADDRESS=$1
    local APT_PROXY_CONFIG=${2:-"/etc/apt/apt.conf.d/80proxy"}

    [[ ! -x "$(command -v apt)" ]] && return 0

    if [[ -n "$PROXY_ADDRESS" ]]; then
        {
            echo -e "Acquire::http::proxy \"http://${PROXY_ADDRESS}/\";"
            echo -e "Acquire::https::proxy \"http://${PROXY_ADDRESS}/\";"
            echo -e "Acquire::ftp::proxy \"http://${PROXY_ADDRESS}/\";"
        } | sudo tee -a "$APT_PROXY_CONFIG" >/dev/null
    else
        # [[ -s "$APT_PROXY_CONFIG" ]] && sudo rm -f "$APT_PROXY_CONFIG"
        {
            echo 'Acquire::http::Proxy "false";'
            echo 'Acquire::https::Proxy "false";'
            echo 'Acquire::ftp::Proxy "false";'
        } | sudo tee -a "$APT_PROXY_CONFIG" >/dev/null
    fi
}

# Disable apt proxy
function disable_apt_proxy() {
    local APT_PROXY_CONFIG=${1:-"/etc/apt/apt.conf.d/95disable-proxy"}

    [[ ! -x "$(command -v apt)" ]] && return 0

    echo -e 'Acquire::http::Proxy "false";' | sudo tee "$APT_PROXY_CONFIG" >/dev/null
    echo -e 'Acquire::https::Proxy "false";' | sudo tee -a "$APT_PROXY_CONFIG" >/dev/null
    echo -e 'Acquire::ftp::Proxy "false";' | sudo tee -a "$APT_PROXY_CONFIG" >/dev/null
}

# Set yum proxy
function set_yum_proxy() {
    local PROXY_ADDRESS=${1:-"_none_"}
    local YUM_PROXY_CONFIG=${2:-"/etc/yum.conf"}

    [[ ! -x "$(command -v yum)" ]] && return 0

    # sudo sed -i "s/[#]*[ ]*proxy.*/proxy=_none_/" "$YUM_PROXY_CONFIG"
    sudo sed -i "/[#]*[ ]*proxy.*/d" "$YUM_PROXY_CONFIG"
    echo "proxy=socks5://${PROXY_ADDRESS}" | sudo tee -a "$YUM_PROXY_CONFIG" >/dev/null
}

# Set wget proxy
function set_wget_proxy() {
    local PROXY_ADDRESS=$1
    local WGET_CONFIG=${2:-"$HOME/.wgetrc"}

    [[ ! -x "$(command -v wget)" ]] && return 0

    if [[ -s "$WGET_CONFIG" ]]; then
        sed -i "/^use_proxy.*/d" "$WGET_CONFIG"
        sed -i "/^http_proxy.*/d" "$WGET_CONFIG"
        sed -i "/^https_proxy.*/d" "$WGET_CONFIG"
        sed -i "/^ftp_proxy.*/d" "$WGET_CONFIG"
        sed -i "/^no_proxy.*/d" "$WGET_CONFIG"
    fi

    if [[ -n "$PROXY_ADDRESS" ]]; then
        echo "use_proxy=on" >> "$WGET_CONFIG"
        echo "http_proxy=http://${PROXY_ADDRESS}/" >> "$WGET_CONFIG"
        echo "https_proxy=http://${PROXY_ADDRESS}/" >> "$WGET_CONFIG"
        echo "ftp_proxy=http://${PROXY_ADDRESS}/" >> "$WGET_CONFIG"
        echo "no_proxy=${GLOBAL_NO_PROXY}" >> "$WGET_CONFIG"
    fi
}

# Set curl socks proxy
function set_curl_socks_proxy() {
    local PROXY_ADDRESS=$1
    local CURL_CONFIG=${2:-"$HOME/.curlrc"}

    [[ ! -x "$(command -v curl)" ]] && return 0

    if [[ -s "$CURL_CONFIG" ]]; then
        sed -i "/^socks5-hostname.*/d" "${CURL_CONFIG}"
        sed -i "/^noproxy.*/d" "${CURL_CONFIG}"
    fi

    if [[ -n "$PROXY_ADDRESS" ]]; then
        echo "socks5-hostname=${PROXY_ADDRESS}" >> "${CURL_CONFIG}"
        echo "noproxy=${GLOBAL_NO_PROXY}" >> "${CURL_CONFIG}"
    fi
}

# Set npm http proxy
function set_npm_proxy() {
    local PROXY_ADDRESS=$1

    [[ ! -x "$(command -v npm)" ]] && return 0

    if [[ -n "$PROXY_ADDRESS" ]]; then
        npm config set proxy "http://${PROXY_ADDRESS}"
        npm config set https-proxy "http://${PROXY_ADDRESS}"
    else
        npm config delete proxy
        npm config delete https-proxy
    fi
}

# Set yarn http proxy
function set_yarn_proxy() {
    local PROXY_ADDRESS=$1

    [[ ! -x "$(command -v yarn)" ]] && return 0

    if [[ -n "$PROXY_ADDRESS" ]]; then
        yarn config set proxy "http://${PROXY_ADDRESS}"
        yarn config set https-proxy "http://${PROXY_ADDRESS}"
    else
        yarn config delete proxy
        yarn config delete https-proxy
    fi
}

# Set gradle http proxy
function set_gradle_proxy() {
    local PROXY_HOST=$1
    local PROXY_PORT=$2
    local GRADLE_CONFIG=${3:-"$HOME/.gradle/gradle.properties"}

    [[ ! -x "$(command -v gradle)" ]] && return 0

    if [[ -s "$GRADLE_CONFIG" ]]; then
        sed -i "/^systemProp.http.proxyHost.*/d" "${GRADLE_CONFIG}"
        sed -i "/^systemProp.http.proxyPort.*/d" "${GRADLE_CONFIG}"
        sed -i "/^systemProp.https.proxyHost.*/d" "${GRADLE_CONFIG}"
        sed -i "/^systemProp.https.proxyPort.*/d" "${GRADLE_CONFIG}"
    fi

    if [[ -n "$PROXY_HOST" && -n "$PROXY_PORT" ]]; then
        echo "systemProp.http.proxyHost=${PROXY_HOST}" >> "${GRADLE_CONFIG}"
        echo "systemProp.http.proxyPort=${PROXY_PORT}" >> "${GRADLE_CONFIG}"
        echo "systemProp.https.proxyHost=${PROXY_HOST}" >> "${GRADLE_CONFIG}"
        echo "systemProp.https.proxyPort=${PROXY_PORT}" >> "${GRADLE_CONFIG}"
    fi
}

# Set ruby gem proxy
function set_gem_proxy() {
    local PROXY_ADDRESS=$1
    local GEM_CONFIG=${2:-"$HOME/.gemrc"}

    [[ ! -x "$(command -v gem)" ]] && return 0

    if [[ -s "$GEM_CONFIG" ]]; then
        sed -i "/^http_proxy.*/d" "$GEM_CONFIG"
    fi

    if [[ -n "$PROXY_ADDRESS" ]]; then
        echo "http_proxy: http://${PROXY_ADDRESS}" >> "$GEM_CONFIG"
    fi
}

# Set global proxy
function set_global_proxy() {
    local SOCKS_ADDRESS=${1:-""}
    local HTTP_ADDRESS=${2:-""}
    local SOCKS_PROTOCOL=${3:-"socks5"}

    # clear all proxy first
    clear_all_proxy

    [[ -z "${SOCKS_ADDRESS}" && -z "${HTTP_ADDRESS}" ]] && return 1

    if [[ -n "${HTTP_ADDRESS}" ]]; then
        set_proxy "http://${HTTP_ADDRESS}"

        colorEcho "${GREEN}  :: Now using ${FUCHSIA}http://${HTTP_ADDRESS} ${GREEN}for global proxy!"
    elif [[ -n "${SOCKS_ADDRESS}" ]]; then
        set_proxy "${SOCKS_PROTOCOL}://${SOCKS_ADDRESS}"

        set_curl_socks_proxy "${SOCKS_ADDRESS}"

        colorEcho "${GREEN}  :: Now using ${FUCHSIA}${SOCKS_PROTOCOL}://${SOCKS_ADDRESS} ${GREEN}for global proxy!"
    fi

    # wget must use http proxy
    if [[ -n "${HTTP_ADDRESS}" ]]; then
        set_wget_proxy "${HTTP_ADDRESS}"
        # colorEcho "${GREEN}  :: Now using ${FUCHSIA}${HTTP_ADDRESS} ${GREEN}for http proxy(wget etc.)!"
    fi

    return 0
}

# Check & set global proxy
function check_set_global_proxy() {
    local SOCKS_PORT=${1:-"1080"}
    local MIXED_PORT=${2:-"8080"}
    local PROXY_IP
    local PROXY_SOCKS=""
    local SOCKS_PROTOCOL="socks5"
    local PROXY_HTTP=""
    local IP_LIST="127.0.0.1"
    local IP_WSL
    local PROXY_SOCKS_UP="NO"
    local PROXY_HTTP_UP="NO"
    local CMD_DIR

    if check_os_wsl2; then
        # WSL2
        # Fix "Invalid argument" when executing Windows commands
        CMD_DIR=$(dirname "$(which ipconfig.exe)")
        IP_LIST=$(cd "${CMD_DIR}" && ipconfig.exe | grep -a "IPv4" \
                    | grep -Eo '([0-9]{1,3}[\.]){3}[0-9]{1,3}' \
                    | grep -Ev "^0\.|^127\.|^172\.")
        IP_WSL=$(grep -m1 nameserver /etc/resolv.conf | awk '{print $2}')
        IP_LIST=$(echo -e "${IP_LIST}\n${IP_WSL}" | uniq)
        # IP_LIST=$(echo -e "${IP_WSL}\n${IP_LIST}" | uniq)
    fi

    # unset GLOBAL_PROXY_IP
    # unset GLOBAL_PROXY_SOCKS_PROTOCOL
    # unset GLOBAL_PROXY_SOCKS_PORT
    # unset GLOBAL_PROXY_MIXED_PORT

    # {
    #     echo ''
    #     echo '# Global proxy settings'
    #     echo 'export GLOBAL_PROXY_IP=192.168.0.1'
    #     echo 'export GLOBAL_PROXY_SOCKS_PROTOCOL=socks5'
    #     echo 'export GLOBAL_PROXY_SOCKS_PORT=7890'
    #     echo 'export GLOBAL_PROXY_MIXED_PORT=7890'
    # } >> "$HOME/.zshenv"

    if [[ -n "${GLOBAL_PROXY_IP}" ]]; then
        IP_LIST=$(echo -e "${GLOBAL_PROXY_IP}\n${IP_LIST}" | uniq)
        SOCKS_PROTOCOL="${GLOBAL_PROXY_SOCKS_PROTOCOL:-${SOCKS_PROTOCOL}}"
        SOCKS_PORT="${GLOBAL_PROXY_SOCKS_PORT:-${SOCKS_PORT}}"
        MIXED_PORT="${GLOBAL_PROXY_MIXED_PORT:-${MIXED_PORT}}"
    fi

    # Set global proxy
    while read -r PROXY_IP; do
        # if check_socks5_proxy_up "${PROXY_IP}:${MIXED_PORT}"; then
        #     SOCKS_PORT="${MIXED_PORT}"
        #     PROXY_UP="YES"
        # else
        #     if check_socks5_proxy_up "${PROXY_IP}:${SOCKS_PORT}"; then
        #         if ! check_http_proxy_up "${PROXY_IP}:${MIXED_PORT}"; then
        #             MIXED_PORT=""
        #         fi
        #         PROXY_UP="YES"
        #     fi
        # fi

        # Use HTTP proxy by default
        if check_http_proxy_up "${PROXY_IP}:${MIXED_PORT}"; then
            PROXY_HTTP_UP="YES"
        else
            if check_socks5_proxy_up "${PROXY_IP}:${MIXED_PORT}"; then
                SOCKS_PORT="${MIXED_PORT}"
                PROXY_SOCKS_UP="YES"
            elif check_socks5_proxy_up "${PROXY_IP}:${SOCKS_PORT}"; then
                PROXY_SOCKS_UP="YES"
            fi
        fi

        [[ "${PROXY_HTTP_UP}" == "YES" || "${PROXY_SOCKS_UP}" == "YES" ]] && break
    done <<<"${IP_LIST}"

    [[ "${PROXY_HTTP_UP}" == "NO" ]] && MIXED_PORT=""
    [[ "${PROXY_SOCKS_UP}" == "NO" ]] && SOCKS_PORT=""

    if [[ "${PROXY_HTTP_UP}" == "YES" || "${PROXY_SOCKS_UP}" == "YES" ]]; then
        [[ -n "${SOCKS_PORT}" ]] && PROXY_SOCKS="${PROXY_IP}:${SOCKS_PORT}"
        [[ -n "${MIXED_PORT}" ]] && PROXY_HTTP="${PROXY_IP}:${MIXED_PORT}"

        if set_global_proxy "${PROXY_SOCKS}" "${PROXY_HTTP}" "${SOCKS_PROTOCOL}"; then
            export GLOBAL_PROXY_IP="${PROXY_IP}"
            export GLOBAL_PROXY_SOCKS_PROTOCOL="${SOCKS_PROTOCOL}"
            export GLOBAL_PROXY_SOCKS_PORT="${SOCKS_PORT}"
            export GLOBAL_PROXY_MIXED_PORT="${MIXED_PORT}"

            check_os_wsl2 && export GLOBAL_WSL2_HOST_IP="${PROXY_IP}"

            return 0
        fi
    else
        set_global_proxy # clear global proxy

        return 1
    fi
}

# Set special app socks5 proxy (curl...)
function set_special_socks5_proxy() {
    local SOCKS5_PROXY=${1:-""}

    CURL_SPECIAL_CONFIG=${CURL_SPECIAL_CONFIG:-"$HOME/.curl_socks5"}

    if [[ -n "$SOCKS5_PROXY" ]]; then
        set_curl_socks_proxy "${SOCKS5_PROXY}" "${CURL_SPECIAL_CONFIG}"
    else
        # cat /dev/null > "${CURL_SPECIAL_CONFIG}"
        [[ -f "${CURL_SPECIAL_CONFIG}" ]] && rm "${CURL_SPECIAL_CONFIG}"
    fi
}

# download clash config & restart clash
function downloadClashConfig() {
    # Usage: downloadClashConfig "https://transfer.sh/xxxx/clash.yaml.enc" "/srv/clash/clash.yaml.enc" "$HOME/keyfile.key" "/srv/clash/clash.yaml"
    local download_url=$1
    local download_filename=$2
    local encrypt_keyfile=$3
    local decrypt_filename=$4

    if [[ ! -s "/srv/clash/clash" ]]; then
        colorEcho "${RED}  Please install and run ${FUCHSIA}clash${RED} first!"
        return 1
    fi

    if downloadDecryptFile "${download_url}" "${download_filename}" "${encrypt_keyfile}" "${decrypt_filename}"; then
        if /srv/clash/clash -f /srv/clash/public.yml -t; then
            sudo cp -f "/srv/clash/public.yml" "/srv/clash/config.yaml"
            sudo systemctl restart clash
            sleep 3

            if check_socks5_proxy_up "127.0.0.1:7890"; then
                colorEcho "${GREEN}The configuration looks ok!"
            else
                sudo journalctl -u clash --since "1 minutes ago" -e
            fi
        fi
    fi
}
