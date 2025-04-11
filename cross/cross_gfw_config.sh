#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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
[[ ! -x "$(command -v jq)" ]] && PackagesList=(jq) && InstallSystemPackages "" "${PackagesList[@]}"

if [[ ! -x "$(command -v jq)" ]]; then
    colorEcho "${FUCHSIA}jq${RED} is not installed!"
    exit 1
fi

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
    if check_os_wsl; then
        :
    else
        colorEcho "${BLUE}  Checking & loading ${FUCHSIA}clash${BLUE} proxy..."

        [[ -s "/srv/subconverter/subconverter" ]] || install_update_subconverter
        [[ -s "/srv/subconverter/subconverter" ]] || {
                colorEcho "${RED}  Please install and run ${FUCHSIA}subconverter${RED} first!"
                return 1
            }

        systemctl is-enabled subconverter >/dev/null 2>&1 || {
                Install_systemd_Service "subconverter" "/srv/subconverter/subconverter"
            }

        [[ -s "/srv/clash/clash" ]] || install_update_clash
        [[ -s "/srv/clash/clash" ]] || {
                colorEcho "${RED}  Please install and run ${FUCHSIA}clash${RED} first!"
                return 1
            }

        systemctl is-enabled clash >/dev/null 2>&1 || {
                Install_systemd_Service "clash" "/srv/clash/clash -d /srv/clash"
            }

        if systemctl is-enabled clash >/dev/null 2>&1; then
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

        [[ -z "${GLOBAL_PROXY_IP}" ]] && use_clash 127.0.0.1 "${GLOBAL_PROXY_SOCKS_PORT:-7891}" "${GLOBAL_PROXY_MIXED_PORT:-7890}"

        setGlobalProxies
    fi
}


main