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


# [[ -x "$(command -v proxychains4)" && -d "$HOME/proxychains-ng" && $UID -eq 0 ]] && \
#     isUpgrade="yes"
# [[ ! -x "$(command -v proxychains4)" && ! -d "$HOME/proxychains-ng" && $UID -eq 0 ]] && \
#     isNewInstall="yes"
# if [[ "$isUpgrade" == "yes" || "$isNewInstall" == "yes" ]]; then

# proxychains
if [[ -x "$(command -v proxychains4)" ]]; then
    if [[ -d "$HOME/proxychains-ng" ]]; then
        colorEcho "${BLUE}Updating ${FUCHSIA}proxychains-ng${BLUE}..."

        Git_Clone_Update_Branch "rofl0r/proxychains-ng" "$HOME/proxychains-ng"

        # only recompile if update
        # git_latest_update=$(git log -1 --format="%at" | xargs -I{} date -d @{} +'%Y-%m-%d %H:%M:%S')
        git_latest_update=$(git log -1 --format="%at" | xargs -I{} date -d @{})
        proxychains4_date=$(date -d "$(stat --printf='%y\n' "$(which proxychains4)")")
        # if [[ $(date -d "$git_latest_update") > $(date --date='7 day ago') ]]; then
        if [[ $(date -d "$git_latest_update") > $(date -d "$proxychains4_date") ]]; then
            cd "$HOME/proxychains-ng" && \
                sudo ./configure --prefix=/usr --sysconfdir=/etc/proxychains >/dev/null && \
                sudo make >/dev/null && sudo make install >/dev/null
        fi
    fi
else
    PackagesList=(proxychains4)
    InstallSystemPackages "${BLUE}Installing ${FUCHSIA}proxychains-ng${BLUE}..." "${PackagesList[@]}"

    if [[ ! -x "$(command -v proxychains4)" ]]; then
        Git_Clone_Update_Branch "rofl0r/proxychains-ng" "$HOME/proxychains-ng"

        if [[ -d "$HOME/proxychains-ng" ]]; then
            cd "$HOME/proxychains-ng" && \
                sudo ./configure --prefix=/usr --sysconfdir=/etc/proxychains >/dev/null && \
                sudo make >/dev/null && sudo make install >/dev/null && sudo make install-config >/dev/null
        fi
    fi

    isNewInstall="yes"
fi

if [[ "$isNewInstall" == "yes" ]]; then
    PROXYCHAINS_CONFIG="/etc/proxychains/proxychains.conf"
    [[ ! -s "${PROXYCHAINS_CONFIG}" ]] && \
        PROXYCHAINS_CONFIG="/etc/proxychains4.conf"

    if [[ -s "${PROXYCHAINS_CONFIG}" ]]; then
        sudo cp ${PROXYCHAINS_CONFIG} ${PROXYCHAINS_CONFIG}.bak && \
            sudo sed -i 's/socks4/# socks4/g' ${PROXYCHAINS_CONFIG}

        check_set_global_proxy "${GLOBAL_PROXY_SOCKS_PORT:-7891}" "${GLOBAL_PROXY_MIXED_PORT:-7890}"

        if [[ -n "${GLOBAL_PROXY_IP}" ]]; then
            echo 'socks5 ${GLOBAL_PROXY_IP} ${GLOBAL_PROXY_SOCKS_PORT}' | sudo tee -a ${PROXYCHAINS_CONFIG} >/dev/null
        fi
    fi
fi

cd "${CURRENT_DIR}" || exit