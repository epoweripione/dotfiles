#!/usr/bin/env bash

## Partitioning
## https://wiki.archlinux.org/title/Partitioning

## Btrfs
## https://wiki.archlinux.org/title/btrfs
## https://blog.kaaass.net/archives/1748

## New install
# https://arch.icekylin.online/
# 1. Terminal Emulator
# sudo pacman-mirrors -i -c China -m rank
# sudo pacman -Syy
# 2. GParted:
# sudo pacman -S gparted
# Device→Create partition table→gpt
# +8MB→unformatted→BIOS_GRUB
# +512MB→fat32→EFI
# +8192MB→linux-swap→Swap
# +20480MB→ext4→root
# +30720MB→ext4→usr
# +51200MB→ext4→var
# +...→ext4→home
# 3. Launch installer
# BIOS_GRUB→delete→create→unformatted→bios_grub
# EFI→/boot/efi
# root→/
# usr→/usr
# var→/var
# home→/home
# 4. Clash for Windows
# sudo pacman -S nftables iproute2
# Service Mode→Manage→install→TUN Mode
# 5.xray
# ${MY_SHELL_SCRIPTS}/cross/xray_installer.sh
# sudo nano /usr/local/etc/xray/config.json
# sudo systemctl enable "xray" && sudo systemctl restart "xray"

## Reinstall Manjaro preserving the $USER files and settings
## https://forum.manjaro.org/t/reinstall-manjaro-preserving-the-user-files-and-settings/104721
## https://wiki.archlinux.org/title/Migrate_installation_to_new_hardware

## kill jobs with jobspec
# jobs && kill %1

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

# Local WAN GEO location
[[ -z "${NETWORK_WAN_NET_IP_GEO}" ]] && get_network_wan_geo
[[ "${NETWORK_WAN_NET_IP_GEO}" =~ 'China' || "${NETWORK_WAN_NET_IP_GEO}" =~ 'CN' ]] && IP_GEO_IN_CHINA="yes"

# Setup network proxy in desktop environment
[[ -s "${MY_SHELL_SCRIPTS}/manjaro/desktop_proxy.sh" ]] && \
    source "${MY_SHELL_SCRIPTS}/manjaro/desktop_proxy.sh"

## Configuration for locking the user after multiple failed authentication attempts
# sudo sed -i 's/[#]*[ ]*deny.*/deny = 5/' "/etc/security/faillock.conf"
# sudo sed -i 's/[#]*[ ]*unlock_time.*/unlock_time = 60/' "/etc/security/faillock.conf"


# pacman
# Generate custom mirrorlist
if [[ "${IP_GEO_IN_CHINA}" == "yes" ]]; then
    colorEcho "${BLUE}Generating ${FUCHSIA}mirror lists${BLUE}..."
    sudo pacman-mirrors -i -c China -m rank
fi

# Show colorful output on the terminal
sudo sed -i 's|^#Color|Color|' /etc/pacman.conf

# Full update
colorEcho "${BLUE}Updating ${FUCHSIA}full system${BLUE}..."
sudo pacman --noconfirm --needed -Syu

# Language packs
colorEcho "${BLUE}Installing ${FUCHSIA}language packs${BLUE}..."
sudo pacman --noconfirm --needed -S firefox-i18n-zh-cn thunderbird-i18n-zh-cn man-pages-zh_cn

[[ -x "$(command -v gimp)" ]] && sudo pacman --noconfirm --needed -S gimp-help-zh_cn

# Build deps
sudo pacman --noconfirm --needed -S patch pkg-config automake

## Arch Linux Chinese Community Repository
## https://github.com/archlinuxcn/mirrorlist-repo
if [[ "${IP_GEO_IN_CHINA}" == "yes" ]]; then
    colorEcho "${BLUE}Installing${FUCHSIA} archlinuxcn ${BLUE} repo..."
    if ! grep -q "archlinuxcn" /etc/pacman.conf 2>/dev/null; then
        echo "[archlinuxcn]" | sudo tee -a /etc/pacman.conf >/dev/null
        # echo "Server = https://repo.archlinuxcn.org/\$arch" | sudo tee -a /etc/pacman.conf >/dev/null
        echo "Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch" | sudo tee -a /etc/pacman.conf >/dev/null
    fi

    ## archlinuxcn-keyring 安装时出现可能是因为时空扭曲或系统时钟，密钥生成于未来的N秒后的问题
    # sudo pacman --noconfirm --needed -S haveged && \
    #     sudo systemctl enable haveged && \
    #     sudo systemctl start haveged && \
    #     sudo rm -rf /etc/pacman.d/gnupg && \
    #     sudo pacman-key --init && \
    #     sudo pacman-key --populate

    # sudo pacman --noconfirm --needed -S haveged && \
    #     sudo systemctl enable haveged && \
    #     sudo systemctl start haveged && \
    #     sudo rm -rf /etc/pacman.d/gnupg && \
    #     sudo pacman-key --refresh-keys && \
    #     sudo pacman-key --init && \
    #     sudo pacman-key --populate manjaro && \
    #     sudo pacman-key --populate archlinux && \
    #     sudo pacman-key --populate archlinuxcn && \
    #     sudo pacman -Scc && sudo pacman --noconfirm --needed -Syu

    sudo pacman --noconfirm --needed -Syy && \
        sudo pacman --noconfirm --needed -S archlinuxcn-keyring && \
        sudo pacman --noconfirm --needed -S archlinuxcn-mirrorlist-git
fi


# Python
[[ -s "${MY_SHELL_SCRIPTS}/installer/python_pip_config.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/python_pip_config.sh"


# Default editor
# ZSH: https://apple.stackexchange.com/questions/388622/zsh-zprofile-zshrc-zlogin-what-goes-where
# .zshenv → .zprofile → .zshrc → .zlogin → .zlogout
if [[ -x "$(command -v nano)" ]]; then
    colorEcho "${BLUE}Setting default editor to ${FUCHSIA}nano${BLUE}..."
    if ! grep -q "^export VISUAL=" "$HOME/.bash_profile" 2>/dev/null; then
        echo 'export VISUAL="nano" && export EDITOR="nano"' >> "$HOME/.bash_profile"
    fi

    if ! grep -q "^export VISUAL=" "$HOME/.zprofile" 2>/dev/null; then
        echo 'export VISUAL="nano" && export EDITOR="nano"' >> "$HOME/.zprofile"
    fi
fi


## Mount NFTS Drive & fix read-only mount NFTS Drive
# sudo fdisk -l
# sudo lsblk
# sudo blkid
# sudo ntfsfix /dev/sdb1
# sudo mkdir -p /mnt/sdb1
# sudo mount -t ntfs-3g /dev/sdb1 /mnt/sdb1
# sudo findmnt
# sudo umount /mnt/sdb1

## Automount
# echo "UUID=$(sudo blkid | grep '/dev/sdb1' | grep -Eo '\s+UUID="[^"]*"' | cut -d\" -f2) /mnt/sdb1 ntfs-3g defaults 0 0" | sudo tee -a "/etc/fstab"


# Running in virtual environment
[[ -z "${OS_INFO_VIRTUALIZED}" ]] && get_os_virtualized

# sshd
if [[ "${OS_INFO_VIRTUALIZED}" != "none" ]]; then
    colorEcho "${BLUE}Enabling ${FUCHSIA}sshd${BLUE}..."
    [[ $(systemctl is-enabled sshd 2>/dev/null) ]] || \
        { sudo systemctl enable sshd; sudo systemctl start sshd; }
fi

# Virtualbox
# https://wiki.manjaro.org/index.php?title=VirtualBox
# https://forum.manjaro.org/t/howto-virtualbox-installation-usb-shared-folders/55905
if [[ "${OS_INFO_VIRTUALIZED}" == "oracle" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}virtualbox-guest-utils${BLUE}..."
    sudo pacman --noconfirm --needed -S virtualbox-guest-utils
    # linux_ver=linux$(uname -r | cut -d'.' -f1-2 | sed 's/\.//')
    # sudo pacman --noconfirm --needed -S "${linux_ver}-virtualbox-guest-modules"
fi

# pre-requisite packages
colorEcho "${BLUE}Installing ${FUCHSIA}pre-requisite packages${BLUE}..."
sudo pacman --noconfirm --needed -S bind git curl wget unzip seahorse yay fx


# Network
[[ -s "${MY_SHELL_SCRIPTS}/manjaro/network_setup.sh" ]] && source "${MY_SHELL_SCRIPTS}/manjaro/network_setup.sh"


# iTerm2-Color-Schemes
# https://github.com/mbadolato/iTerm2-Color-Schemes
if [[ -x "$(command -v xfce4-terminal)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}iTerm2-Color-Schemes${BLUE}..."
    Git_Clone_Update_Branch "mbadolato/iTerm2-Color-Schemes" "$HOME/iTerm2-Color-Schemes"
    if [[ -d "$HOME/iTerm2-Color-Schemes" ]]; then
        mkdir -p "$HOME/.local/share/xfce4/terminal/colorschemes" && \
            cp "$HOME/iTerm2-Color-Schemes/xfce4terminal/colorschemes/"*.theme \
                "$HOME/.local/share/xfce4/terminal/colorschemes"
    fi
fi


# yay
# https://github.com/Jguer/yay
# yay <Search Term>               Present package-installation selection menu.
# yay -Ps                         Print system statistics.
# yay -Yc                         Clean unneeded dependencies.
# yay -G <AUR Package>            Download PKGBUILD from ABS or AUR.
# yay -Y --gendb                  Generate development package database used for devel update.
# yay -Syu --devel --timeupdate   Perform system upgrade, but also check for development package updates and 
#                                     use PKGBUILD modification time (not version number) to determine update.


# Fonts & Input Methods for CJK locale
[[ -s "${MY_SHELL_SCRIPTS}/manjaro/cjk_locale_setup.sh" ]] && source "${MY_SHELL_SCRIPTS}/manjaro/cjk_locale_setup.sh"


## RDP Server
## http://www.xrdp.org/
## https://wiki.archlinux.org/index.php/xrdp
# colorEcho "${BLUE}Installing ${FUCHSIA}xrdp${BLUE}..."
# yay --noconfirm --needed -S xrdp
# echo 'allowed_users=anybody' | sudo tee -a /etc/X11/Xwrapper.config
# sudo systemctl enable xrdp xrdp-sesman && \
#     sudo systemctl start xrdp xrdp-sesman


# RDP Client
colorEcho "${BLUE}Installing ${FUCHSIA}RDP client${BLUE}..."
sudo pacman --noconfirm --needed -S freerdp remmina
# yay -S rustdesk


# Change from exfat-utils to exfatprogs for exfat
colorEcho "${BLUE}Installing ${FUCHSIA}exfatprogs${BLUE}..."
yay --needed -S exfatprogs


# Desktop
colorEcho "${BLUE}Installing ${FUCHSIA}desktop components${BLUE}..."
# sudo pacman --noconfirm --needed -S dmenu

# picom: a standalone compositor for Xorg, a fork of compton
# rofi: a window switcher, run dialog, ssh-launcher and dmenu replacement
# feh: Fast and light imlib2-based image viewer
# inkscape: Professional vector graphics editor
# mate-power-manager: Power management tool for the MATE desktop
# mpd: Flexible, powerful, server-side application for playing music
# ncmpcpp: Fully featured MPD client using ncurses
# polybar: A fast and easy-to-use status bar
# scrot: command-line screenshot utility for X
# xcompmgr: Composite Window-effects manager for X.org
sudo pacman --noconfirm --needed -S picom rofi feh inkscape mate-power-manager mpd ncmpcpp polybar scrot

## xmonad https://xmonad.org/
# sudo pacman --noconfirm --needed -S xmonad xmonad-contrib xmonad-utils slock xmobar

## i3 https://i3wm.org/
## https://www.zhihu.com/question/62251457
## https://github.com/levinit/i3wm-config
## https://zocoxx.com/archlinux-i3wm.html
# sudo pacman --noconfirm --needed -S i3-gaps
# sudo pacman --noconfirm --needed -S i3-scripts i3-scrot i3blocks i3lock i3status i3exit
# sudo pacman --noconfirm --needed -S arc-icon-theme adwaita-icon-theme lxappearance manjaro-wallpapers-by-lunix-i3
## conky-i3 dmenu-manjaro i3-default-artwork i3-help
## i3status-manjaro manjaro-i3-settings manjaro-i3-settings-bldbk

## DWM
## https://wiki.archlinux.org/index.php/Dwm_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
## https://github.com/GoDzM4TT3O/dotfiles
# git clone --recurse-submodules https://github.com/GoDzM4TT3O/dotfiles && \
#     cd dotfiles && \
#     cp -r .{config,vim*,z*,x*,X*,alias*,p10k.zsh,local} $HOME && \
#     cp -r dwm $HOME


# Apps
# Broswer
colorEcho "${BLUE}Installing ${FUCHSIA}broswer${BLUE}..."
yay --noconfirm --needed -S chromium google-chrome
# yay --noconfirm --needed -S google-chrome-beta
# yay --noconfirm --needed -S google-chrome-dev
# yay --noconfirm --needed -S microsoft-edge-stable-bin

# Clipborad
colorEcho "${BLUE}Installing ${FUCHSIA}copyq${BLUE}..."
sudo pacman --noconfirm --needed -S copyq

# Develop
colorEcho "${BLUE}Installing ${FUCHSIA}develop tools${BLUE}..."
sudo pacman --noconfirm --needed -S dbeaver wireshark-qt
yay --noconfirm --needed -S visual-studio-code-bin

# Dictionary
# sudo pacman --noconfirm --needed -S goldendict-git

# Download & Upload
colorEcho "${BLUE}Installing ${FUCHSIA}download & upload tools${BLUE}..."
sudo pacman --noconfirm --needed -S aria2 motrix you-get filezilla

# Docker
colorEcho "${BLUE}Installing ${FUCHSIA}docker${BLUE}..."
sudo pacman --noconfirm --needed -S docker docker-compose
# yay -S kitematic

# File & dir compare
colorEcho "${BLUE}Installing ${FUCHSIA}meld${BLUE}..."
sudo pacman --noconfirm --needed -S meld

# Free disk space and maintain privacy
colorEcho "${BLUE}Installing ${FUCHSIA}bleachbit${BLUE}..."
sudo pacman --noconfirm --needed -S bleachbit

# IM
colorEcho "${BLUE}Installing ${FUCHSIA}IM tools${BLUE}..."
yay --noconfirm --needed -S telegram-desktop linuxqq deepin-wine-qq deepin-wine-wechat wemeet-bin
# yay --noconfirm --needed -S deepin-wine-tim

# Markdown
colorEcho "${BLUE}Installing ${FUCHSIA}markdown tools${BLUE}..."
sudo pacman --noconfirm --needed -S vnote-git
# sudo pacman --noconfirm --needed -S typora

# Note
# yay --noconfirm --needed -S leanote
# sudo pacman --noconfirm --needed -S wiznote
# sudo pacman --noconfirm --needed -S cherrytree

# Netdisk
colorEcho "${BLUE}Installing ${FUCHSIA}netdisk${BLUE}..."
yay --noconfirm --needed -S baidunetdisk-bin

# Password manager
colorEcho "${BLUE}Installing ${FUCHSIA}password manager${BLUE}..."
sudo pacman --noconfirm --needed -S enpass keepass bitwarden

# PDF Reader
colorEcho "${BLUE}Installing ${FUCHSIA}PDF reader${BLUE}..."
sudo pacman --noconfirm --needed -S evince
# yay --noconfirm --needed -S foxitreader

# Player
colorEcho "${BLUE}Installing ${FUCHSIA}video & audio players${BLUE}..."
sudo pacman --noconfirm --needed -S netease-cloud-music
sudo pacman --noconfirm --needed -S smplayer smplayer-skins smplayer-themes
# yay --noconfirm --needed -S qqmusic-bin

# Proxy
colorEcho "${BLUE}Installing ${FUCHSIA}proxy tools${BLUE}..."
# sudo pacman --noconfirm --needed -S proxychains-ng v2ray
sudo pacman --noconfirm --needed -S frps frpc

# Screenshot
colorEcho "${BLUE}Installing ${FUCHSIA}screenshot tools${BLUE}..."
sudo pacman --noconfirm --needed -S deepin-screenshot flameshot
# sudo pacman --noconfirm --needed -S xfce4-screenshooter

# Search
colorEcho "${BLUE}Installing ${FUCHSIA}search tools${BLUE}..."
sudo pacman --noconfirm --needed -S synapse utools
yay --noconfirm --needed -S albert-bin

# Linux Advanced Power Management
colorEcho "${BLUE}Installing ${FUCHSIA}power management tools${BLUE}..."
sudo pacman --noconfirm --needed -S tlp tlp-rdw tlpui
sudo tlp start
# sudo tlp-stat -s # System Info
# sudo tlp-stat -b # Battery Care

# System
colorEcho "${BLUE}Installing ${FUCHSIA}system tools${BLUE}..."
sudo pacman --noconfirm --needed -S btop font-manager filelight peek redshift ventoy-bin
# yay --noconfirm --needed -S easystroke

# Terminal
# sudo pacman --noconfirm --needed -S konsole

## Virtualbox
# yay --noconfirm --needed -S aur/virtualbox-bin
# yay --noconfirm --needed -S aur/virtualbox-ext-oracle

# WPS
colorEcho "${BLUE}Installing ${FUCHSIA}WPS Office${BLUE}..."
yay --noconfirm --needed -S wps-office-cn wps-office-mui-zh-cn wps-office-mime-cn
yay --noconfirm --needed -S wps-office-fonts ttf-wps-fonts wps-office-all-dicts-win-languages


## pyenv
## https://segmentfault.com/a/1190000006174123
# sudo pacman --noconfirm --needed -S pyenv

# pyenv init
# pyenv install --list
# pyenv install <version>
# v=3.9.8;wget https://npmmirror.com/mirrors/python/$v/Python-$v.tar.xz -P ~/.pyenv/cache/;pyenv install $v
# pyenv versions
# pyenv uninstall <version>
# pyenv global <version>


## penetration testing
# sudo pacman --noconfirm --needed -S metasploit msfdb nmap hydra sqlmap
# sudo msfdb-blackarch init
# sudo msfdb-blackarch start


# KVM & QEMU
[[ -s "${MY_SHELL_SCRIPTS}/manjaro/qemu_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/manjaro/qemu_installer.sh"

# Conky
[[ -s "${MY_SHELL_SCRIPTS}/manjaro/conky_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/manjaro/conky_installer.sh"

# Rustdesk
[[ -s "${MY_SHELL_SCRIPTS}/installer/rustdesk_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/rustdesk_installer.sh"

# Go
[[ -s "${MY_SHELL_SCRIPTS}/installer/goup_go_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/goup_go_installer.sh"

# Rust
[[ -s "${MY_SHELL_SCRIPTS}/installer/cargo_rust_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/cargo_rust_installer.sh"

# Node
[[ -s "${MY_SHELL_SCRIPTS}/nodejs/nvm_node_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/nodejs/nvm_node_installer.sh"

# Flutter & Android Studio
[[ -s "${MY_SHELL_SCRIPTS}/installer/flutter_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/flutter_installer.sh"

# Homebrew
[[ -s "${MY_SHELL_SCRIPTS}/installer/homebrew_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/homebrew_installer.sh"


# Clean jobs
# sudo pacman -Rns $(pacman -Qtdq)
colorEcho "${BLUE}Cleaning pacman cache..."
yay --noconfirm -Yc


## Change default data location for some applications: docker, kvm...
# [[ -s "${MY_SHELL_SCRIPTS}/manjaro/change_apps_data_location.sh" ]] && \
#     source "${MY_SHELL_SCRIPTS}/manjaro/change_apps_data_location.sh"


# Auto shutdown at 20:00
# (crontab -l 2>/dev/null || true; echo "0 20 * * * sync && shutdown -h now") | crontab -


cd "${CURRENT_DIR}" || exit
