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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

## OpenWrt
## https://openwrt.org/docs/guide-user/installation/openwrt_x86
## https://gparted.org/livecd.php
## use `GParted LiveCD` or `Debian LiveCD` to write the image file to the drive you want to install OpenWrt in <sdX>
## <sdX> is the name of the drive you want to write the image on
# wget "https://downloads.openwrt.org/snapshots/targets/x86/64/openwrt-x86-64-generic-ext4-combined-efi.img.gz" && \
#     gzip -d "openwrt-x86-64-generic-ext4-combined-efi.img.gz" && \
#     dd if=openwrt-x86-64-generic-ext4-combined-efi.img.gz of=/dev/<sdX>

## LOG MESSAGES
# To read the content of the membuffer that syslogd writes to, use the `logread` utility 
# for kernel messages use `dmesg`

## Resize Ext4 rootfs for `combined-ext4.img`
## https://openwrt.org/docs/guide-user/installation/openwrt_x86#resizing_partitions
## Fix: GPT PMBR size mismatch
## https://post.m.smzdm.com/p/a7857e8g/

## Get PARTUUID
# block info
# blkid
# lsusb -t
# parted -l

## use `GParted LiveCD` or `Debian LiveCD` to resize the partition /dev/sda2 & add /dev/sda3 for A/B Upgrades
# sudo -i
# apt update && apt install -y gparted
# cfdisk # choose `write` to fix: GPT PMBR size mismatch
## open gparted and resize the second partition

## https://openwrt.org/docs/guide-user/luci/luci.essentials
## https://openwrt.org/zh-cn/doc/howto/luci.essentials

## https://gist.github.com/pjobson/3584f36dadc8c349fac9abf1db22b5dc
## https://shenyu.me/2021/02/26/x86-64-install-openwrt.html
## https://www.solarck.com/lede-media-center2.html

## https://www.10bests.com/install-openwrt-lede-on-pve/
# qm importdisk 100 /var/lib/vz/template/iso/openwrt.img local-lvm

## list devices
# ubus -v list
# ubus -v list "network.interface.*"
# uci show network

# system info
cat /etc/banner && cat /tmp/sysinfo/board_name && cat /tmp/sysinfo/model

# Copy current kernel to rootfs
cp /boot/vmlinuz /vmlinuz

# Preserving opkg lists
sed -i -e "/^lists_dir\s/s:/var/opkg-lists$:/usr/lib/opkg/lists:" "/etc/opkg.conf"

# opkg mirror
if ! grep -q 'SNAPSHOT' "/etc/banner"; then
    sed -i 's_downloads.openwrt.org_mirrors.tuna.tsinghua.edu.cn/openwrt_' "/etc/opkg/distfeeds.conf"
fi

opkg update
opkg install bash ca-bundle ca-certificates curl git git-http nano rsync tmux unzip vim-full wget zsh \
    kmod-fs-ext4 kmod-fs-f2fs kmod-fs-ntfs kmod-usb-core kmod-usb-storage kmod-usb-ohci kmod-usb-uhci \
    block-mount f2fs-tools mount-utils pciutils usbutils swap-utils \
    blkid cfdisk coreutils-stat dumpe2fs e2fsprogs fdisk lsblk parted resize2fs tune2fs \
    libustream-mbedtls

# PROXY_ADDRESS="http://localhost:7890" && export {http,https,ftp,all}_proxy="${PROXY_ADDRESS}" &&  export {HTTP,HTTPS,FTP,ALL}_PROXY="${PROXY_ADDRESS}"
# PROXY_ADDRESS="http://localhost:7890" && export http_proxy="${PROXY_ADDRESS}" && export https_proxy="${PROXY_ADDRESS}" && export all_proxy="${PROXY_ADDRESS}"
# echo "use_proxy=on" >> "$HOME/.wgetrc" && echo "http_proxy=http://localhost:7890/" >> "$HOME/.wgetrc" && echo "https_proxy=http://localhost:7890/" >> "$HOME/.wgetrc"

# Oh My Zsh
# sh -c "$(wget -O- https://raw.githubusercontent.com/felix-fly/openwrt-ohmyzsh/master/install.sh)"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# zsh theme
sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"ys\"/" "$HOME/.zshrc"

# Change shell to ZSH
which zsh >/dev/null && sed -i -- 's:/bin/ash:'"$(which zsh)"':g' "/etc/passwd"

# LuCI
# /etc/config/luci
opkg install luci-ssl luci-i18n-base-zh-cn luci-i18n-uhttpd-zh-cn luci-i18n-firewall-zh-cn luci-i18n-opkg-zh-cn
/etc/init.d/uhttpd enable && /etc/init.d/uhttpd start
# opkg list luci-app-\* | awk '{print $1}' | while read -r line; do opkg install "$line"; done
# opkg list luci-i18n-\*-zh-cn | awk '{print $1}' | while read -r line; do opkg install "$line"; done

## Accessing LuCI web interface securely
## https://openwrt.org/docs/guide-user/luci/luci.secure

## allow wan ssh into openwrt
## flush all firewall rules
## iptables -F
# tee -a "/etc/config/firewall" >/dev/null <<-'EOF'
# 
# config rule
#     option src              'wan'
#     option dest_port        '22'
#     option target           'ACCEPT'
#     option proto            'tcp'
# EOF
# /etc/init.d/firewall restart

## authorized_keys location
# /etc/dropbear/authorized_keys

## network
## https://openwrt.org/docs/guide-user/network/ucicheatsheet
## uci show network
## nano /etc/config/network
# uci set network.lan.ipaddr=<new-ip-address>
# uci set network.wan.proto=static
# uci set network.wan.ipaddr=<static-ip-address>
# uci set network.wan.netmask=<netmask-ip-address>
# uci set network.wan.gateway=<gateway-ip-address>
# uci set network.wan.dns=<dns-ip-address>
# uci commit && service network restart

## DHCP
## https://openwrt.org/docs/guide-user/base-system/dhcp
## dnsmasq --help dhcp
## uci -N show dhcp.@dhcp[0]
## nano /etc/config/dhcp
## `config dhcp 'lan'`
## list 'dhcp_option' '6,114.114.114.114,1.1.1.1,8.8.8.8'
# /etc/init.d/dnsmasq restart

## Disable ipv6
# /etc/init.d/odhcpd disable && /etc/init.d/odhcpd stop

## https://github.com/richb-hanover/OpenWrtScripts
## https://github.com/tavinus/opkg-upgrade

## Apply latest package updates
## https://zhmail.com/2019/02/02/upgrading-an-openwrt-18-06-1-x86_64-ext4-image-to-18-06-2/
## https://blog.christophersmart.com/2018/03/18/auto-apply-latest-package-updates-on-openwrt-lede-project/
## Upgrade all non-core packages
## Upgrade netifd first
# opkg upgrade netifd

# opkg list-upgradable 2>/dev/null | cut -d' ' -f1 | xargs -r opkg upgrade
# opkg list-upgradable 2>/dev/null | awk '{print $1}' | while IFS='$\n' read -r line; do opkg upgrade "$line"; done

## Upgrade Kernel
# . /etc/openwrt_release
# CURRENT_KERNEL="$(opkg list-installed kernel)" && INSTALLER_VER_CURRENT="${CURRENT_KERNEL##* }"
# INSTALLER_VER_REMOTE=$(wget -qO- https://downloads.openwrt.org/snapshots/targets/${DISTRIB_TARGET}/packages/ \
#     | grep -Eo -m1 '>kernel_.*\.ipk' \
#     | sed -e 's/>kernel_//' -e 's/\.ipk//' -e "s|_${DISTRIB_TARGET/\//_}||" \
#     | head -n1)

# if version_gt "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
#     cd /tmp
#     wget "https://downloads.openwrt.org/snapshots/targets/${DISTRIB_TARGET}/packages/kernel_${INSTALLER_VER_REMOTE}_${DISTRIB_TARGET/\//_}.ipk" && \
#         opkg install "kernel_${INSTALLER_VER_REMOTE}_${DISTRIB_TARGET/\//_}.ipk"

#     # Edit /etc/opkg/distfeeds.conf
#     sed -i '/openwrt_kmods/d' "/etc/opkg/distfeeds.conf"
#     echo "src/gz openwrt_kmods https://downloads.openwrt.org/snapshots/targets/${DISTRIB_TARGET}/kmods/${INSTALLER_VER_REMOTE}" >> "/etc/opkg/distfeeds.conf"
# fi

## Upgrade the base-files package
# chmod -x "/lib/functions.sh" && opkg upgrade base-files

# Reconfigure DNS setting in /etc/resolv.conf

## Upgrade all other core packages
# opkg list-upgradable 2>/dev/null | awk '{print $1}' | grep -Ev 'netifd|base-files|kmod|Multiple' | while read -r line; do opkg upgrade "$line"; done
## fix error `check_data_file_clashes: Package <> wants to install file <> But that file is already provided by package`
# opkg list-upgradable 2>/dev/null | awk '{print $1}' | grep -Ev 'netifd|base-files|kmod|Multiple' | while read -r line; do opkg upgrade --nodeps --force-depends "$line"; done

# reboot


## OpenClash
## https://github.com/vernesong/OpenClash
opkg remove dnsmasq
opkg install dnsmasq-full

opkg install luci luci-base iptables coreutils coreutils-nohup \
    bash curl jsonfilter ca-certificates ipset ip-full iptables-mod-tproxy kmod-tun luci-compat \
    libcap libcap-bin jq perl

# Pre-release
INSTALLER_CHECK_URL="https://api.github.com/repos/vernesong/OpenClash/tags"
INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" | grep 'name' | head -n1 | cut -d\" -f4 | cut -d'v' -f2)

if [[ -n "${INSTALLER_VER_REMOTE}" ]]; then
    INSTALLER_FILE_NAME="luci-app-openclash_${INSTALLER_VER_REMOTE}_all.ipk"
    INSTALLER_DOWNLOAD_URL="https://github.com/vernesong/OpenClash/releases/download/v${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"

    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "/tmp/${INSTALLER_FILE_NAME}" "${INSTALLER_DOWNLOAD_URL}" && \
        opkg install "/tmp/${INSTALLER_FILE_NAME}"
fi

## remove
## opkg remove luci-app-openclash


## [ChinaDNS-NG]((https://github.com/zfl9/chinadns-ng))
## https://iwan.ga/archives/401
## https://github.com/NagaseKouichi/openwrt-chinadns-ng
opkg install chinadns-ng

INSTALL_PKGS=(
    # "https://github.com/NagaseKouichi/openwrt-chinadns-ng/releases/download/luci-app-chinadns-ng_1.2-1_all/chinadns-ng_1.0-beta.24-1_x86_64.ipk"
    "https://github.com/NagaseKouichi/openwrt-chinadns-ng/releases/download/luci-app-chinadns-ng_1.2-1_all/luci-app-chinadns-ng_1.2-1_all.ipk"
    "https://github.com/NagaseKouichi/openwrt-chinadns-ng/releases/download/luci-app-chinadns-ng_1.2-1_all/luci-i18n-chinadns-ng-zh-cn_1.2-1_all.ipk"
)
for TargetUrl in "${INSTALL_PKGS[@]}"; do
    INSTALLER_DOWNLOAD_FILE=$(basename "${TargetUrl}" | cut -d'?' -f1)
    if App_Installer_Download_Extract "${TargetUrl}" "${INSTALLER_DOWNLOAD_FILE}" "${WORKDIR}"; then
        opkg install "${WORKDIR}/${INSTALLER_DOWNLOAD_FILE}"
    fi
done

## DNS list
# rsync -avhz --progress /opt/chinadns-ng/*.txt root@10.0.0.1:/etc/chinadns-ng
Git_Clone_Update_Branch "zfl9/chinadns-ng" "$HOME/chinadns-ng"
if [[ -d "/tmp/chinadns-ng" ]]; then
    cd "/tmp/chinadns-ng" && \
        ./update-gfwlist.sh && ./update-chnlist.sh && ./update-chnroute.sh && ./update-chnroute6.sh

    cp -f "/tmp/chinadns-ng/chnlist.txt" "/etc/chinadns-ng/chinalist.txt"
    cp -f "/tmp/chinadns-ng/gfwlist.txt" "/etc/chinadns-ng/gfwlist.txt"

    sed '1d' "/tmp/chinadns-ng/chnroute.ipset" | awk '{print $3}' | tee "/etc/chinadns-ng/chnroute.txt" >/dev/null
    sed '1d' "/tmp/chinadns-ng/chnroute6.ipset" | awk '{print $3}' | tee "/etc/chinadns-ng/chnroute6.txt" >/dev/null
fi


## [naiveproxy](https://github.com/klzgrad/naiveproxy/wiki/OpenWrt-Support)
# cat /etc/os-release
# OPENWRT_ARCH="$(. /etc/os-release && echo "${OPENWRT_ARCH}")"
# App_Installer_Get_Remote_URL "https://api.github.com/repos/klzgrad/naiveproxy/releases/latest" "naiveproxy-.*openwrt-${OPENWRT_ARCH}.*\.tar\.xz"
opkg install naiveproxy luci-app-naiveproxy


## [procd-init-scripts](https://openwrt.org/docs/guide-developer/procd-init-scripts)
## [openwrt procd init script 自启动脚本服务](https://blog.niekun.net/archives/2277.html)
## [frp 自动启动](https://gist.github.com/h1code2/3a749d966ed5ef36e4836d24c3f7d3d8)


cd "${CURRENT_DIR}" || exit
