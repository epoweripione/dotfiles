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

[[ -z "${OS_INFO_DESKTOP}" ]] && get_os_desktop

# Setup network proxy in desktop environment
if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    PROXY_HTTP_HOST="${GLOBAL_PROXY_IP}" && PROXY_HTTP_PORT="${GLOBAL_PROXY_MIXED_PORT}"
    PROXY_SOCKS_HOST="${GLOBAL_PROXY_IP}" && PROXY_SOCKS_PORT="${GLOBAL_PROXY_SOCKS_PORT}"
    PROXY_NOPROXY=${GLOBAL_NO_PROXY:-""}

    if [[ "${OS_INFO_DESKTOP}" == "GNOME" ]]; then
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


cd "${CURRENT_DIR}" || exit
