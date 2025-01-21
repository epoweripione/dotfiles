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

App_Installer_Reset

# [Pigsty - PostgreSQL In Great STYle](https://pigsty.io/)

# Allow user sudo to execute any command without password prompt
echo "$(whoami) ALL=(ALL:ALL) NOPASSWD:ALL,\!/bin/su" | sudo tee "/etc/sudoers.d/nopasswd_sudo_$(whoami)" >/dev/null && \
    sudo chmod 440 "/etc/sudoers.d/nopasswd_sudo_$(whoami)"

# curl -fsSL https://repo.pigsty.io/get | bash
# cd "$HOME/pigsty" || exit
# ./bootstrap
# ./configure
# ./install.yml
# chmod a-x install.yml

curl https://repo.pigsty.io/pig | bash

[[ ! -x "$(command -v pig)" ]] && exit

pig sty init     # 默认安装嵌入的最新 Pigsty 版本
pig sty boot     # 执行 Bootstrap，安装 Ansible
pig sty conf     # 执行 Configure，生成配置文件
pig sty install  # 执行 install.yml 剧本完成部署

## The PGSQL provides a PostgreSQL singleton which can be accessed via:
# psql postgres://dbuser_dba:DBUser.DBA@10.10.10.10/meta     # DBA / superuser (via IP)
# psql postgres://dbuser_meta:DBUser.Meta@10.10.10.10/meta   # business admin, read / write / ddl
# psql postgres://dbuser_view:DBUser.View@pg-meta/meta       # read-only user

## The INFRA module gives you an entire modern observability stack, exposed by Nginx on (80 / 443):
## There are several services are exposed by Nginx (configured by infra_portal):
# Component	    Port	Domain	    Comment	                    Public Demo
# Nginx	        80/443	h.pigsty	Web Service Portal, Repo	home.pigsty.cc
# AlertManager	9093	a.pigsty	Alter Aggregator	        a.pigsty.cc
# Grafana	    3000	g.pigsty	Grafana Dashboard Home	    demo.pigsty.cc
# Prometheus	9090	p.pigsty	Prometheus Web UI	        p.pigsty.cc

## Grafana Dashboards (g.pigsty, port 3000) credentials, user: admin / pass: pigsty

## How to access Pigsty Web UI by domain name?
get_network_local_ip_default
if [[ -n "${NETWORK_LOCAL_IP_DEFAULT}" ]]; then
    if ! grep -q "h.pigsty" "/etc/hosts"; then
        {
            echo "${NETWORK_LOCAL_IP_DEFAULT} h.pigsty"
            echo "${NETWORK_LOCAL_IP_DEFAULT} a.pigsty"
            echo "${NETWORK_LOCAL_IP_DEFAULT} g.pigsty"
            echo "${NETWORK_LOCAL_IP_DEFAULT} p.pigsty"
        } | sudo tee -a "/etc/hosts" >/dev/null
    fi
fi

cd "${CURRENT_DIR}" || exit
