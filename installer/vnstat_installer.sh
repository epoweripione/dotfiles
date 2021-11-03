#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

colorEcho "${BLUE}Installing ${FUCHSIA}vnstat${BLUE}..."
if [[ -x "$(command -v pacman)" ]]; then
    PackagesList=(
        sqlite
        sqlite-devel
        libsqlite3-dev
    )
    for TargetPackage in "${PackagesList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
            sudo pacman --noconfirm -S "${TargetPackage}"
        fi
    done
fi


cd "${WORKDIR}" && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o vnstat.tar.gz "https://humdi.net/vnstat/vnstat-latest.tar.gz" && \
    tar -xzf vnstat.tar.gz && \
    mv vnstat-* vnstat && cd vnstat/ && \
    sudo ./configure --prefix=/usr --sysconfdir=/etc >/dev/null && \
    sudo make >/dev/null && \
    sudo make install >/dev/null && \
    : && \
    sudo cp -v examples/systemd/vnstat.service /etc/systemd/system/ && \
    sudo sed -i -e '/^ProtectSystem=/d' /etc/systemd/system/vnstat.service && \
    sudo systemctl enable vnstat && \
    sudo systemctl start vnstat

cd "${CURRENT_DIR}" || exit

# 如遇到 Failed to restart vnstat.service: Unit vnstat.service is masked.
# 请删除 /etc/systemd/system/ 下的 vnstat.service 文件

# Error: Unable to open database "/var/lib/vnstat/vnstat.db": No such file or directory
# update-rc.d vnstat defaults && service vnstat start
# [ -d /var/lib/vnstat ] && rm -rf /var/lib/vnstat
# mkdir -p /var/lib/vnstat && chown -R vnstat:vnstat /var/lib/vnstat

# 定时生成数据库
# vnstat -u -i eth0

# nano /etc/cron.d/vnstat
# # 写入如下内容
# 0-55/5 *        * * *   root   vnstat -u -i eth0
# 0-55/5 *        * * *   root   vnstat --dumpdb -i eth0 >/var/lib/vnstat/vnstat_dump_eth0

# service vnstat restart
