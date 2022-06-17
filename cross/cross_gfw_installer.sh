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


# # Shadowsocks
# # Shadowsocks-Python：/etc/shadowsocks-python/config.json
# # ShadowsocksR: /etc/shadowsocks-r/config.json
# # Shadowsocks-Go：/etc/shadowsocks-go/config.json
# # Shadowsocks-libev：/etc/shadowsocks-libev/config.json

# # ./shadowsocks_exec.sh start | stop | restart | status
# if [[ ! -e "$HOME/shadowsocks_exec.sh" ]]; then
#     cat > shadowsocks_exec.sh <<EOF
# #!/usr/bin/env bash

# [ -e /etc/init.d/shadowsocks-r ] && /etc/init.d/shadowsocks-r \$1
# [ -e /etc/init.d/shadowsocks-libev ] && /etc/init.d/shadowsocks-libev \$1
# [ -e /etc/init.d/shadowsocks-python ] && /etc/init.d/shadowsocks-r \$1
# [ -e /etc/init.d/shadowsocks-go ] && /etc/init.d/shadowsocks-libev \$1

# if [ -x "\$(command -v supervisorctl)" ]; then
#     supervisorctl \$1 kcptun
# fi
# EOF

#     chmod +x shadowsocks_exec.sh
# fi


# if [[ -s "$HOME/shadowsocks-all.sh" ]]; then
#     source "$HOME/shadowsocks_exec.sh stop"
#     source "$HOME/shadowsocks-all.sh uninstall"
#     rm -fr shadowsocks-all* && rm -fr mbedtls-* libsodium-*
# fi

# # https://github.com/teddysun/shadowsocks_install/tree/master
# wget https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh && \
#     chmod +x shadowsocks-all.sh && \
#     ./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log


# # Kcptun
# # https://github.com/kuoruan/shell-scripts/
# wget -O kcptun.sh https://github.com/kuoruan/shell-scripts/raw/master/kcptun/kcptun.sh && \
#     sh kcptun.sh


## Multi-V2Ray
## https://github.com/Jrohy/multi-v2ray
## /etc/v2ray_util/util.cfg
## /etc/v2ray/config.json
# sudo rm -rf /etc/localtime && \
#     TZ="Asia/Shanghai" && \
#     sudo ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
#     echo $TZ | sudo tee /etc/timezone >/dev/null

# if [[ ! -x "$(command -v v2ray-util)" ]]; then
#     colorEcho "${BLUE}Installing ${FUCHSIA}v2ray-util${BLUE}..."

#     source <(curl -fsSL https://multi.netlify.com/v2ray.sh) --zh
#     # source <(curl -fsSL https://git.io/fNgqx) --zh
# fi


[[ -s "${MY_SHELL_SCRIPTS}/cross/xray_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/cross/xray_installer.sh"

[[ -s "${MY_SHELL_SCRIPTS}/cross/v2ray_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/cross/v2ray_installer.sh"

[[ -s "${MY_SHELL_SCRIPTS}/cross/trojan_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/cross/trojan_installer.sh"

[[ -s "${MY_SHELL_SCRIPTS}/cross/clash_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/cross/clash_installer.sh"

[[ -s "${MY_SHELL_SCRIPTS}/cross/subconverter_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/cross/subconverter_installer.sh"

cd "${CURRENT_DIR}" || exit