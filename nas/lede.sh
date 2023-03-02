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

# PROXY_ADDRESS="socks5://localhost:7890" && export {http,https,ftp,all}_proxy="${PROXY_ADDRESS}" && export {HTTP,HTTPS,FTP,ALL}_PROXY="${PROXY_ADDRESS}"
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

OS_INFO_WSL=$(uname -r)

# Lean's OpenWrt source
# https://github.com/coolsnowwolf/lede
# https://github.com/SuLingGG/OpenWrt-Env
sudo apt-get update && apt-get -y upgrade

sudo apt-get -y install antlr3 asciidoc autoconf automake autopoint binutils build-essential bzip2 \
    curl device-tree-compiler flex g++-multilib gawk gcc-multilib gettext git git-core gperf \
    lib32gcc1 libc6-dev-i386 libelf-dev libglib2.0-dev libncurses5-dev libssl-dev libtool libz-dev \
    msmtp p7zip p7zip-full patch python2.7 python3 qemu-utils rsync subversion swig \
    texinfo uglifyjs unzip upx wget xmlto zlib1g-dev

Git_Clone_Update_Branch "coolsnowwolf/lede" "$HOME/lede"

cd "$HOME/lede" || exit

./scripts/feeds update -a && ./scripts/feeds install -a

if [[ ! -s "$HOME/lede/.config" ]]; then
    # First time compile
    cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nas/lede.config" "$HOME/lede/.config"

    make menuconfig
    make -j8 download V=s

    if check_os_wsl; then
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make -j1 V=s
    else
        make -j1 V=s
    fi
else
    # Recompile
    make defconfig
    make -j8 download

    if check_os_wsl; then
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make -j$(($(nproc) + 1)) V=s
    else
        make -j$(($(nproc) + 1)) V=s
    fi
fi
