#!/usr/bin/env bash

## Partitioning
## https://wiki.archlinux.org/title/Partitioning

## Btrfs
## https://wiki.archlinux.org/title/btrfs
## https://blog.kaaass.net/archives/1748

## New install
# https://arch.icekylin.online/
# 1. Terminal Emulator
# sudo pacman-mirrors -i --geoip --timeout 2 -m rank
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

# Setup pacman repository & AUR & install pre-requisite packages
[[ -s "${MY_SHELL_SCRIPTS}/manjaro/packages_setup.sh" ]] && source "${MY_SHELL_SCRIPTS}/manjaro/packages_setup.sh"

# Setup network proxy in desktop environment
[[ -s "${MY_SHELL_SCRIPTS}/manjaro/desktop_proxy.sh" ]] && source "${MY_SHELL_SCRIPTS}/manjaro/desktop_proxy.sh"

# SSH
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
# cp -f ./ssh/* "$HOME/.ssh" && chmod 600 "$HOME/.ssh/"*

# Force the creation of English-named directories
# [XDG user directories](https://wiki.archlinux.org/title/XDG_user_directories)
sudo pacman --noconfirm --needed -S xdg-user-dirs
LC_ALL=C xdg-user-dirs-update --force

FOLDER_EN=(Desktop Documents Downloads Pictures Music Videos Public Templates)
FOLDER_CN=(桌面 文档 下载 图片 音乐 视频 公共 模板)
FOLDER_INDEX=-1
for TargetFolder in "${FOLDER_CN[@]}"; do
    FOLDER_INDEX=$((FOLDER_INDEX + 1))
    if [[ -d "${HOME:-/home/$(id -nu)}/${TargetFolder}" ]]; then
        FOLDER_SRC="${HOME:-/home/$(id -nu)}/${TargetFolder}"
        FOLDER_DEST="${HOME:-/home/$(id -nu)}/${FOLDER_EN[$FOLDER_INDEX]}"
        [[ "$(ls -A "${FOLDER_SRC}")" ]] && cp -r "${FOLDER_SRC}/"* "${FOLDER_DEST}"
        rm -rf "${HOME:-/home/$(id -nu)}/${TargetFolder}"
    fi

    # Dolphin places
    if [[ -s "$HOME/.local/share/user-places.xbel" ]]; then
        FOLDER_ENCODE=$(tr -d '\n' <<<"${TargetFolder}" | od -An -tx1 | tr ' ' %)
        sed -i -e "s/${FOLDER_ENCODE}/${FOLDER_EN[$FOLDER_INDEX]}/g" "$HOME/.local/share/user-places.xbel"
    fi
done

# sed -i -e 's|XDG_DESKTOP_DIR=.*|XDG_DESKTOP_DIR="$HOME/Desktop"|' \
#         -e 's|XDG_DOCUMENTS_DIR=.*|XDG_DOCUMENTS_DIR="$HOME/Documents"|' \
#         -e 's|XDG_DOWNLOAD_DIR=.*|XDG_DOWNLOAD_DIR="$HOME/Downloads"|' \
#         -e 's|XDG_PICTURES_DIR=.*|XDG_PICTURES_DIR="$HOME/Pictures"|' \
#         -e 's|XDG_MUSIC_DIR=.*|XDG_MUSIC_DIR="$HOME/Music"|' \
#         -e 's|XDG_VIDEOS_DIR=.*|XDG_VIDEOS_DIR="$HOME/Videos"|' \
#         -e 's|XDG_PUBLICSHARE_DIR=.*|XDG_PUBLICSHARE_DIR="$HOME/Public"|' \
#         -e 's|XDG_TEMPLATES_DIR=.*|XDG_TEMPLATES_DIR="$HOME/Templates"|' \
#     "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs"

# FOLDER_INDEX=-1
# for TargetFolder in "${FOLDER_CN[@]}"; do
#     FOLDER_INDEX=$((FOLDER_INDEX + 1))
#     [[ -d "${HOME:-/home/$(id -nu)}/${TargetFolder}" ]] && mv "${HOME:-/home/$(id -nu)}/${TargetFolder}" "${HOME:-/home/$(id -nu)}/${FOLDER_EN[$FOLDER_INDEX]}"
# done

# for TargetFolder in "${FOLDER_EN[@]}"; do
#     [[ ! -d "${HOME:-/home/$(id -nu)}/${TargetFolder}" ]] && mkdir -p "${HOME:-/home/$(id -nu)}/${TargetFolder}"
# done

## Configuration for locking the user after multiple failed authentication attempts
# sudo sed -i 's/[#]*[ ]*deny.*/deny = 5/' "/etc/security/faillock.conf"
# sudo sed -i 's/[#]*[ ]*unlock_time.*/unlock_time = 60/' "/etc/security/faillock.conf"

# snap
[[ -s "${MY_SHELL_SCRIPTS}/installer/snap_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/snap_installer.sh"

# Network
[[ -s "${MY_SHELL_SCRIPTS}/manjaro/network_setup.sh" ]] && source "${MY_SHELL_SCRIPTS}/manjaro/network_setup.sh"

# Fonts & Input Methods for CJK locale
[[ -s "${MY_SHELL_SCRIPTS}/manjaro/cjk_locale_setup.sh" ]] && source "${MY_SHELL_SCRIPTS}/manjaro/cjk_locale_setup.sh"

# Python
[[ -s "${MY_SHELL_SCRIPTS}/installer/python_pip_config.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/python_pip_config.sh"


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
yay --noconfirm --needed -S rustdesk-bin


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
yay --noconfirm --needed -S chromium google-chrome google-chrome-dev
# yay --noconfirm --needed -S google-chrome-beta
# yay --noconfirm --needed -S microsoft-edge-stable-bin

# Clipborad
colorEcho "${BLUE}Installing ${FUCHSIA}copyq${BLUE}..."
sudo pacman --noconfirm --needed -S copyq

# Develop
colorEcho "${BLUE}Installing ${FUCHSIA}develop tools${BLUE}..."
sudo pacman --noconfirm --needed -S jre17-openjdk
sudo pacman --noconfirm --needed -S dbeaver wireshark-qt
yay --noconfirm --needed -S visual-studio-code-bin
yay --noconfirm --needed -S community/geany community/geany-plugins aur/geany-themes
# yay --noconfirm --needed -S aur/notepadnext

# Dictionary
# sudo pacman --noconfirm --needed -S goldendict-git

# Download & Upload
colorEcho "${BLUE}Installing ${FUCHSIA}download & upload tools${BLUE}..."
sudo pacman --noconfirm --needed -S aria2 you-get filezilla archlinuxcn/qbittorrent-enhanced-git
sudo snap install motrix

# Docker
colorEcho "${BLUE}Installing ${FUCHSIA}docker${BLUE}..."
sudo pacman --noconfirm --needed -S docker docker-compose
# yay -S kitematic

## [Podman](https://wiki.archlinux.org/title/Podman)
# yay --noconfirm --needed -S community/podman community/cni-plugins community/buildah
# yay --noconfirm --needed -S community/podman-docker community/podman-compose chaotic-aur/podman-desktop

## Rootless Podman
## sysctl kernel.unprivileged_userns_clone
## If it is currently set to 0, enable it by setting 1 via sysctl or kernel parameter
# sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
# yay --noconfirm --needed -S community/fuse-overlayfs community/podman-dnsname community/slirp4netns
# podman system migrate

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
sudo pacman --noconfirm --needed -S font-manager filelight peek redshift ventoy-bin
# yay --noconfirm --needed -S easystroke

# Terminal
# sudo pacman --noconfirm --needed -S konsole

## [Virtualbox](https://wiki.archlinux.org/title/VirtualBox)
# yay --noconfirm --needed -S community/virtualbox community/virtualbox-guest-iso
# yay --noconfirm --needed -S aur/virtualbox-bin aur/virtualbox-bin-guest-iso aur/virtualbox-ext-oracle
# sudo usermod -aG vboxusers "$USER"

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

# Notepadqq
[[ -s "${MY_SHELL_SCRIPTS}/installer/notepadqq_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/notepadqq_installer.sh"

# Themes
# [[ -s "${MY_SHELL_SCRIPTS}/installer/desktop_themes.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/desktop_themes.sh"

## Others
# mute tone when logout
echo -e "\n# Disable BIOS sound\nxset -b" | sudo tee -a "/etc/xprofile" > /dev/null

# Disable PC speaker
# su -c 'modprobe -r pcspkr && echo "blacklist pcspkr" >> /etc/modprobe.d/50-blacklist.conf'
echo -e "\n# Disable PC speaker\nblacklist pcspkr" | sudo tee "/etc/modprobe.d/nobeep.conf"


# Clean jobs
# sudo pacman -Rns $(pacman -Qtdq)
colorEcho "${BLUE}Cleaning pacman cache..."
yay --noconfirm -Sc && yay --noconfirm -Yc

sudo sh -c 'rm -rf /var/lib/snapd/cache/*'


## Change default data location for some applications: docker, kvm...
# [[ -s "${MY_SHELL_SCRIPTS}/manjaro/change_apps_data_location.sh" ]] && \
#     source "${MY_SHELL_SCRIPTS}/manjaro/change_apps_data_location.sh"


# Auto shutdown at 20:00
# (crontab -l 2>/dev/null || true; echo "0 20 * * * sync && shutdown -h now") | crontab -


cd "${CURRENT_DIR}" || exit
