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

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_DESKTOP}" ]] && get_os_desktop

# Setup network proxy in desktop environment
if [[ "${THE_WORLD_BLOCKED}" == "true" && -n "${GLOBAL_PROXY_IP}" ]]; then
    PROXY_HTTP_HOST="${GLOBAL_PROXY_IP}" && PROXY_HTTP_PORT="${GLOBAL_PROXY_MIXED_PORT}"
    PROXY_SOCKS_HOST="${GLOBAL_PROXY_IP}" && PROXY_SOCKS_PORT="${GLOBAL_PROXY_SOCKS_PORT}"
    PROXY_NOPROXY=${GLOBAL_NO_PROXY:-""}

    # Naiveproxy
    colorEcho "${BLUE}Installing ${FUCHSIA}Naiveproxy${BLUE}..."
    yay --noconfirm --needed -S archlinuxcn/naiveproxy

    # Hysteria
    colorEcho "${BLUE}Installing ${FUCHSIA}Hysteria${BLUE}..."
    yay --noconfirm --needed -S archlinuxcn/hysteria

    # Clash
    # colorEcho "${BLUE}Installing ${FUCHSIA}Clash Premium${BLUE}..."
    # yay --noconfirm --needed -S archlinuxcn/clash-premium-bin

    # colorEcho "${BLUE}Installing ${FUCHSIA}Clash Meta${BLUE}..."
    # yay --noconfirm --needed -S archlinuxcn/clash-meta

    colorEcho "${BLUE}Installing ${FUCHSIA}mihomo${BLUE}..."
    yay --noconfirm --needed -S aur/mihomo

    # Clash for Windows
    # colorEcho "${BLUE}Installing ${FUCHSIA}Clash for Windows${BLUE}..."
    # yay --noconfirm --needed -S nftables iproute2
    # yay --noconfirm --needed -S aur/clash-for-windows-bin

    ## If you want to use clash-meta, install it and run  
    # sudo ln -sf /usr/bin/clash-meta /opt/clash-for-windows/static/files/linux/x64/clash-linux 

    ## To use the TUN mode, you need to run 
    # sudo systemctl start clash-core-service@$USER
    # sudo systemctl enable clash-core-service@$USER

    ## Clash for Windows→General→Service Mode→Manage→install→TUN Mode

    # Clash Verge
    colorEcho "${BLUE}Installing ${FUCHSIA}Clash Verge${BLUE}..."
    yay --noconfirm --needed -S aur/clash-verge-rev-bin

    # Fix `start tun interface error: operation not permitted`
    # [setcap 详解](https://www.cnblogs.com/nf01/articles/10418141.html)
    [[ -x "$(command -v clash)" ]] && sudo setcap cap_net_admin=+eip "$(which clash)"
    [[ -x "$(command -v clash-meta)" ]] && sudo setcap cap_net_admin=+eip "$(which clash-meta)"
    [[ -x "$(command -v mihomo)" ]] && sudo setcap cap_net_admin=+eip "$(which mihomo)"
    [[ -x "$(command -v cfw)" ]] && sudo setcap cap_net_admin=+eip "$(which cfw)"
    [[ -x "$(command -v clash-verge)" ]] && sudo setcap cap_net_admin=+eip "$(which clash-verge)"

    # xray
    colorEcho "${BLUE}Installing ${FUCHSIA}XRay${BLUE}..."
    yay --noconfirm --needed -S archlinuxcn/xray archlinuxcn/xray-geoip archlinuxcn/xray-domain-list-community

    # Install `BypassGFWFirewall` service
    if ! systemctl is-enabled "BypassGFWFirewall" >/dev/null 2>&1; then
        colorEcho "${BLUE}Installing ${FUCHSIA}BypassGFWFirewall${BLUE} service..."
        sudo mkdir -p "/opt/BypassGFWFirewall"
        sudo cp -f "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/BypassGFWFirewall.sh" "/opt/BypassGFWFirewall/BypassGFWFirewall.sh"
        sudo chmod +x "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/BypassGFWFirewall.sh"

        sudo cp -f "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cross/BypassGFWFirewall.service" "/opt/BypassGFWFirewall/BypassGFWFirewall.service"
        sudo sed -i -e "s/username/$(id -nu)/g" "/opt/BypassGFWFirewall/BypassGFWFirewall.service"

        sudo cp -f "/opt/BypassGFWFirewall/BypassGFWFirewall.service" "/etc/systemd/system/BypassGFWFirewall.service"
        sudo systemctl enable --now BypassGFWFirewall
    fi

    if [[ "${OS_INFO_DESKTOP}" == "GNOME" ]]; then
        colorEcho "${BLUE}Setting ${FUCHSIA}GNOME${BLUE} desktop proxies..."
        # https://www.xmodulo.com/change-system-proxy-settings-command-line-ubuntu-desktop.html
        gsettings set org.gnome.system.proxy mode 'manual'

        if [[ -n "${PROXY_HTTP_HOST}" && -n "${PROXY_HTTP_PORT}" ]]; then
            gsettings set org.gnome.system.proxy.http host "${PROXY_HTTP_HOST}"
            gsettings set org.gnome.system.proxy.http port "${PROXY_HTTP_PORT}"

            gsettings set org.gnome.system.proxy.https host "${PROXY_HTTP_HOST}"
            gsettings set org.gnome.system.proxy.https port "${PROXY_HTTP_PORT}"

            gsettings set org.gnome.system.proxy.ftp host "${PROXY_HTTP_HOST}"
            gsettings set org.gnome.system.proxy.ftp port "${PROXY_HTTP_PORT}"
        fi

        if [[ -n "${PROXY_SOCKS_HOST}" && -n "${PROXY_SOCKS_PORT}" ]]; then
            gsettings set org.gnome.system.proxy.socks host "${PROXY_SOCKS_HOST}"
            gsettings set org.gnome.system.proxy.socks port "${PROXY_SOCKS_PORT}"
        fi

        if [[ -n "${PROXY_NOPROXY}" ]]; then
            GNOME_IGNORE_HOSTS=$(sed "s/,/','/g" <<< "'${PROXY_NOPROXY}'")
            gsettings set org.gnome.system.proxy ignore-hosts "[${GNOME_IGNORE_HOSTS}]"
        fi
    fi

    if [[ "${OS_INFO_DESKTOP}" == "KDE" ]]; then
        colorEcho "${BLUE}Setting ${FUCHSIA}KDE${BLUE} desktop proxies..."
        # https://github.com/himanshub16/ProxyMan/blob/master/kde5.sh
        kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key ProxyType 1

        if [[ -n "${PROXY_HTTP_HOST}" && -n "${PROXY_HTTP_PORT}" ]]; then
            kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key httpProxy "http://${PROXY_HTTP_HOST} ${PROXY_HTTP_PORT}"
            kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key httpsProxy "http://${PROXY_HTTP_HOST} ${PROXY_HTTP_PORT}"
            kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key ftpProxy "ftp://${PROXY_HTTP_HOST} ${PROXY_HTTP_PORT}"
        fi

        if [[ -n "${PROXY_SOCKS_HOST}" && -n "${PROXY_SOCKS_PORT}" ]]; then
            kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key socksProxy "socks://${PROXY_SOCKS_HOST} ${PROXY_SOCKS_PORT}"
        fi

        if [[ -n "${PROXY_NOPROXY}" ]]; then
            kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key NoProxyFor "${PROXY_NOPROXY}"
        fi
    fi
else
    if [[ "${OS_INFO_DESKTOP}" == "GNOME" ]]; then
        gsettings set org.gnome.system.proxy mode 'none'
    fi

    if [[ "${OS_INFO_DESKTOP}" == "KDE" ]]; then
        kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key ProxyType 0
    fi
fi


# keep proxy env when running command with `sudo`
echo 'Defaults env_keep += "http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY"' \
    | sudo tee "/etc/sudoers.d/keep_env_proxy" >/dev/null


# Increase the number of connections per proxy to 99
# 99 is the maximum value for MaxConnectionsPerProxy
# [MaxConnectionsPerProxy](https://cloud.google.com/docs/chrome-enterprise/policies/?policy=MaxConnectionsPerProxy)
colorEcho "${BLUE}Setting Chrome ${FUCHSIA}MaxConnectionsPerProxy${BLUE}..."
case "${OS_INFO_TYPE}" in
    linux | freebsd | openbsd)
        sudo mkdir -p "/etc/chromium/policies/managed"
        echo '{ "MaxConnectionsPerProxy": 99 }' | sudo tee "/etc/chromium/policies/managed/proxy.json" >/dev/null
        ;;
    darwin)
        defaults write com.google.Chrome MaxConnectionsPerProxy -int 99
        ;;
    # windows)
	# 	reg add HKLM\Software\Policies\Google\Chrome /v MaxConnectionsPerProxy /t reg_dword /d 00000063 /f
	# 	reg add HKLM\Software\Policies\Chromium /v MaxConnectionsPerProxy /t reg_dword /d 00000063 /f
    #     ;;
esac


cd "${CURRENT_DIR}" || exit
