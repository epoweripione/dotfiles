#!/usr/bin/env bash

## New install
# 1. Terminal Emulator
# sudo pacmna-mirrors -i -c China -m rank
# sudo pacman -Syy
# 2. GParted:
# Device→Create partition table→gpt
# +8MB→unformatted→BIOS_GRUB
# +512MB→fat32→EFI
# +8192MB→linux-swap→Swap
# +102400MB→ext4→Manjaro
# +...→ext4→Home
# 3. Launch installer
# BIOS_GRUB→delete→create→unformatted→bios_grub
# EFI→/boot/eft
# Manjaro→/
# Home→/home
# 4. Clash for Windows
# sudo pacman -S nftables iproute2
# Service Mode→Manage→install→TUN Mode
# 5.xray
# ${MY_SHELL_SCRIPTS}/cross/xray_installer.sh
# sudo nano /usr/local/etc/xray/config.json
# sudo systemctl enable "xray" && sudo systemctl restart "xray"

## kill jobs with jobspec
# jobs && kill %1


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

# Local WAN IP
if [[ -z "$WAN_NET_IP" ]]; then
    get_network_wan_ipv4
    get_network_wan_geo
fi

if [[ "${WAN_NET_IP_GEO}" =~ 'China' || "${WAN_NET_IP_GEO}" =~ 'CN' ]]; then
    IP_GEO_IN_CHINA="yes"
fi

[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)


## Configuration for locking the user after multiple failed authentication attempts
# sudo sed -i 's/[#]*[ ]*deny.*/deny = 5/' "/etc/security/faillock.conf"
# sudo sed -i 's/[#]*[ ]*unlock_time.*/unlock_time = 60/' "/etc/security/faillock.conf"


# # snap
# colorEchoN "${ORANGE}Use socks5 proxy for snap?[y/${CYAN}N${ORANGE}]: "
# read -r SNAP_PROXY_CHOICE
# if [[ "$SNAP_PROXY_CHOICE" == 'y' || "$SNAP_PROXY_CHOICE" == 'Y' ]]; then
#     colorEchoN "${ORANGE}Socks5 proxy address?[${CYAN}127.0.0.1:55880${ORANGE}]: "
#     read -r Sock5Address
#     [[ -z "$Sock5Address" ]] && Sock5Address=127.0.0.1:55880

#     # sudo systemctl edit snapd
#     sudo mkdir -p "/etc/systemd/system/snapd.service.d/"
#     echo -e "[Service]" \
#         | sudo tee -a "/etc/systemd/system/snapd.service.d/override.conf" >/dev/null
#     echo -e "Environment=\"http_proxy=socks5://${Sock5Address}\"" \
#         | sudo tee -a "/etc/systemd/system/snapd.service.d/override.conf" >/dev/null
#     echo -e "Environment=\"https_proxy=socks5://${Sock5Address}\"" \
#         | sudo tee -a "/etc/systemd/system/snapd.service.d/override.conf" >/dev/null

#     sudo systemctl daemon-reload && sudo systemctl restart snapd
# fi


# pacman
# Generate custom mirrorlist
if [[ "$IP_GEO_IN_CHINA" == "yes" ]]; then
    sudo pacman-mirrors -i -c China -m rank
fi

# Show colorful output on the terminal
sudo sed -i 's|^#Color|Color|' /etc/pacman.conf

## Arch Linux Chinese Community Repository
## https://github.com/archlinuxcn/mirrorlist-repo
if [[ "$IP_GEO_IN_CHINA" == "yes" ]]; then
    if ! grep -q "archlinuxcn" /etc/pacman.conf 2>/dev/null; then
        echo "[archlinuxcn]" | sudo tee -a /etc/pacman.conf
        # echo "Server = https://repo.archlinuxcn.org/\$arch" | sudo tee -a /etc/pacman.conf
        echo "Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch" \
            | sudo tee -a /etc/pacman.conf
    fi

    # archlinuxcn-keyring 安装时出现可能是因为时空扭曲或系统时钟，密钥生成于未来的N秒后的问题
    sudo pacman --noconfirm --needed pacman -S haveged && \
        sudo systemctl enable haveged && \
        sudo systemctl start haveged && \
        sudo rm -rf /etc/pacman.d/gnupg && \
        sudo pacman-key --init && \
        sudo pacman-key --populate

    # sudo pacman --noconfirm --needed pacman -S haveged && \
    #     sudo systemctl enable haveged && \
    #     sudo systemctl start haveged && \
    #     sudo rm -rf /etc/pacman.d/gnupg && \
    #     sudo pacman-key --refresh-keys && \
    #     sudo pacman-key --init && \
    #     sudo pacman-key --populate manjaro && \
    #     sudo pacman-key --populate archlinux && \
    #     sudo pacman-key --populate archlinuxcn && \
    #     sudo pacman -Scc && sudo pacman -Syu

    sudo pacman --noconfirm --needed -Syy && \
        sudo pacman --noconfirm --needed -S archlinuxcn-keyring && \
        sudo pacman --noconfirm --needed -S archlinuxcn-mirrorlist-git
fi

# Full update
sudo pacman --noconfirm --needed -Syu


# Language packs
sudo pacman --noconfirm --needed -S \
    firefox-i18n-zh-cn thunderbird-i18n-zh-cn gimp-help-zh_cn \
    libreoffice-still-zh-CN man-pages-zh_cn

# Build deps
sudo pacman --noconfirm --needed -S patch pkg-config automake


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


# sshd
[[ $(systemctl is-enabled sshd 2>/dev/null) ]] || \
    { sudo systemctl enable sshd; sudo systemctl start sshd; }


## Virtualbox
## https://wiki.manjaro.org/index.php?title=VirtualBox
## https://forum.manjaro.org/t/howto-virtualbox-installation-usb-shared-folders/55905
## virtualbox-guest-utils
# colorEchoN "${ORANGE}Install virtualbox-guest-utils?[y/${CYAN}N${ORANGE}]: "
# read -r CHOICE
# if [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]]; then
#     sudo pacman --noconfirm --needed -S virtualbox-guest-utils
#     linux_ver=linux$(uname -r | cut -d'.' -f1-2 | sed 's/\.//')
#     sudo pacman --noconfirm --needed -S "${linux_ver}-virtualbox-guest-modules"
# fi

## winbind
# colorEchoN "${ORANGE}Enable winbind?[y/${CYAN}N${ORANGE}]: "
# read -r CHOICE
# if [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]]; then
#     sudo pacman --noconfirm --needed -S manjaro-settings-samba
#     sudo usermod -a -G sambashare "$(whoami)"
#     sudo systemctl enable winbind && sudo systemctl start winbind
# fi


# pre-requisite packages
colorEcho "${BLUE}Installing ${FUCHSIA}pre-requisite packages${BLUE}..."
sudo pacman --noconfirm --needed -S git curl wget unzip seahorse yay


# use en_US.UTF-8 for terminal
# https://blog.flowblok.id.au/2013-02/shell-startup-scripts.html
# https://wiki.archlinux.org/title/Localization/Chinese
# default locale settings: /etc/locale.conf
if ! grep -q "^export LANG=" "$HOME/.bashrc" 2>/dev/null; then
    tee -a "$HOME/.bashrc" >/dev/null <<-'EOF'

# locale for terminal
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
# export LC_ALL="en_US.UTF-8"
EOF
fi

if ! grep -q "^export LANG=" "$HOME/.zshrc" 2>/dev/null; then
    tee -a "$HOME/.zshrc" >/dev/null <<-'EOF'

# locale for terminal
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
# export LC_ALL="en_US.UTF-8"
EOF
fi

# iTerm2-Color-Schemes
# https://github.com/mbadolato/iTerm2-Color-Schemes
colorEcho "${BLUE}Installing ${FUCHSIA}iTerm2-Color-Schemes${BLUE}..."
Git_Clone_Update_Branch "mbadolato/iTerm2-Color-Schemes" "$HOME/iTerm2-Color-Schemes"
if [[ -d "$HOME/iTerm2-Color-Schemes" ]]; then
    mkdir -p "$HOME/.local/share/xfce4/terminal/colorschemes" && \
        cp "$HOME/iTerm2-Color-Schemes/xfce4terminal/colorschemes/"*.theme \
            "$HOME/.local/share/xfce4/terminal/colorschemes"
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
# colorEcho "${BLUE}Installing ${FUCHSIA}yay${BLUE}..."
# if [[ -d "$HOME/yay" ]]; then
#     cd "$HOME/yay" && git pull && makepkg -si
# else
#     Git_Clone_Update_Branch "yay" "$HOME/yay" "https://aur.archlinux.org/"
#     [[ -d "$HOME/yay" ]] && cd "$HOME/yay" && makepkg -si
# fi

## AUR mirror in china
## if ! check_webservice_up www.google.com; then
# if [[ "$IP_GEO_IN_CHINA" == "yes" ]]; then
#     # ~/.config/yay/config.json
#     # yay -P -g
#     [[ -x "$(command -v yay)" ]] && \
#         yay --aururl "https://aur.archlinux.org" --save
# fi


# Fonts
sudo pacman --noconfirm --needed -S powerline-fonts ttf-fira-code ttf-sarasa-gothic \
    ttf-hannom noto-fonts noto-fonts-extra noto-fonts-emoji noto-fonts-cjk \
    ttf-twemoji unicode-emoji

# sudo pacman --noconfirm --needed -S ttf-dejavu ttf-droid ttf-hack ttf-font-awesome otf-font-awesome \
#     ttf-lato ttf-liberation ttf-linux-libertine ttf-opensans ttf-roboto ttf-ubuntu-font-family

# sudo pacman --noconfirm --needed -S adobe-source-code-pro-fonts adobe-source-sans-fonts adobe-source-serif-fonts \
#     adobe-source-han-sans-cn-fonts adobe-source-han-sans-hk-fonts adobe-source-han-sans-tw-fonts \
#     adobe-source-han-serif-cn-fonts wqy-zenhei wqy-microhei

# FiraCode Nerd Font Complete Mono
colorEchoN "${ORANGE}Download URL for FiraCode-Mono?[${CYAN}Use github by default${ORANGE}]: "
read -r NerdFont_URL
[[ -z "$NerdFont_URL" ]] && \
    NerdFont_URL="https://github.com/epoweripione/fonts/releases/download/v0.1.0/FiraCode-Mono-6.2.0.zip"

mkdir -p "$HOME/patched-fonts/FiraCode-Mono" && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "$HOME/patched-fonts/FiraCode-Mono.zip" ${NerdFont_URL} && \
    unzip -q "$HOME/patched-fonts/FiraCode-Mono.zip" -d "$HOME/patched-fonts/FiraCode-Mono" && \
    sudo mv -f "$HOME/patched-fonts/FiraCode-Mono/" "/usr/share/fonts/" && \
    sudo chmod -R 744 "/usr/share/fonts/FiraCode-Mono"
# fc-list | grep "FiraCode" | column -t -s ":"

# CJK fontconfig & colour emoji
# https://wiki.archlinux.org/title/Localization_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)/Simplified_Chinese_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
sudo tee "/etc/fonts/local.conf" >/dev/null <<-'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <alias>
        <family>sans-serif</family>
        <prefer>
            <family>Noto Sans CJK SC</family>
            <family>Noto Sans CJK TC</family>
            <family>Noto Sans CJK HK</family>
            <family>Noto Sans CJK JP</family>
            <family>Noto Sans CJK KR</family>
            <family>Noto Sans</family>
            <family>Sarasa Gothic SC</family>
            <family>FiraCode Nerd Font Mono</family>
            <family>JetBrainsMono Nerd Font Mono</family>
            <family>Noto Color Emoji</family>
            <family>DejaVu Sans</family>
        </prefer>
    </alias>

    <alias>
        <family>serif</family>
        <prefer>
            <family>Noto Serif CJK SC</family>
            <family>Noto Serif CJK TC</family>
            <family>Noto Serif CJK HK</family>
            <family>Noto Serif CJK JP</family>
            <family>Noto Serif CJK KR</family>
            <family>Noto Serif</family>
            <family>Sarasa Gothic SC</family>
            <family>FiraCode Nerd Font Mono</family>
            <family>JetBrainsMono Nerd Font Mono</family>
            <family>Noto Color Emoji</family>
            <family>DejaVu Serif</family>
        </prefer>
    </alias>

    <alias>
        <family>monospace</family>
        <prefer>
            <family>FiraCode Nerd Font Mono</family>
            <family>JetBrainsMono Nerd Font Mono</family>
            <family>Sarasa Mono SC</family>
            <family>Noto Sans Mono CJK SC</family>
            <family>Noto Sans Mono CJK TC</family>
            <family>Noto Sans Mono CJK HK</family>
            <family>Noto Sans Mono CJK JP</family>
            <family>Noto Sans Mono CJK KR</family>
            <family>Noto Sans Mono</family>
            <family>Noto Color Emoji</family>
            <family>DejaVu Sans Mono</family>
        </prefer>
    </alias>
</fontconfig>
EOF

# update font cache
sudo fc-cache -fv

# Fcitx5 input methods for Chinese Pinyin
# https://github.com/fcitx/fcitx5
# https://blog.rasphino.cn/archive/a-taste-of-fcitx5-in-arch.html
sudo pacman --noconfirm --needed -Rs "$(pacman -Qsq fcitx)"
sudo pacman --noconfirm --needed -S fcitx5-im && \
    sudo pacman --noconfirm --needed -S fcitx5-material-color fcitx5-chinese-addons && \
    sudo pacman --noconfirm --needed -S fcitx5-pinyin-zhwiki fcitx5-pinyin-moegirl

if ! grep -q "^GTK_IM_MODULE" "$HOME/.pam_environment" 2>/dev/null; then
    tee -a "$HOME/.pam_environment" >/dev/null <<-'EOF'
# fcitx
GTK_IM_MODULE DEFAULT=fcitx
QT_IM_MODULE  DEFAULT=fcitx
XMODIFIERS    DEFAULT=\@im=fcitx
SDL_IM_MODULE DEFAULT=fcitx
EOF
fi

if ! grep -q "^export GTK_IM_MODULE" "$HOME/.xprofile" 2>/dev/null; then
    tee -a "$HOME/.xprofile" >/dev/null <<-'EOF'
# fcitx5
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
export SDL_IM_MODULE=fcitx

# auto start fcitx5
fcitx5 &
EOF
fi

# fcitx5 theme
# https://github.com/hosxy/Fcitx5-Material-Color
mkdir -p "$HOME/.config/fcitx5/conf"
if ! grep -q "^Vertical Candidate List" "$HOME/.config/fcitx5/conf/classicui.conf" 2>/dev/null; then
    tee -a "$HOME/.config/fcitx5/conf/classicui.conf" >/dev/null <<-'EOF'
Vertical Candidate List=False
PerScreenDPI=True
Font="更纱黑体 SC Medium 13"

Theme=Material-Color-Blue
EOF
fi


## RDP Server
## http://www.xrdp.org/
## https://wiki.archlinux.org/index.php/xrdp
# yay --noconfirm --needed -S xrdp
# echo 'allowed_users=anybody' | sudo tee -a /etc/X11/Xwrapper.config
# sudo systemctl enable xrdp xrdp-sesman && \
#     sudo systemctl start xrdp xrdp-sesman


# RDP Client
sudo pacman --noconfirm --needed -S freerdp remmina


# # NoMachine
# # https://www.nomachine.com/DT02O00124
# wget -c -O nomachine_x86_64.tar.gz \
#     https://download.nomachine.com/download/6.8/Linux/nomachine_6.8.1_1_x86_64.tar.gz && \
#     sudo tar -xzf nomachine_x86_64.tar.gz -C /usr && \
#     sudo /usr/NX/nxserver --install

# # UPDATE
# cd /usr
# wget -c -O nomachine_x86_64.tar.gz \
#     https://download.nomachine.com/download/6.8/Linux/nomachine_6.8.1_1_x86_64.tar.gz && \
#     sudo tar -xzf nomachine_x86_64.tar.gz -C /usr && \
#     sudo /usr/NX/nxserver --update

# # UNINSTALL
# sudo /usr/NX/scripts/setup/nxserver --uninstall && sudo rm -rf /usr/NX


## Conky
# sudo pacman --noconfirm --needed -S conky
sudo pacman --noconfirm --needed -S conky-lua-nv conky-manager jq lua-clock-manjaro

## System info
# lspci
# lscpu
# sudo lshw -class CPU
# sudo dmidecode --type processor
# lspci | grep VGA
# sudo lshw -C video
# sudo lshw -C network

# conky-colors
# https://github.com/helmuthdu/conky_colors
# http://forum.ubuntu.org.cn/viewtopic.php?f=94&t=313031
# http://www.manongzj.com/blog/4-lhjnjqtantllpnj.html
yay --noconfirm --needed -S conky-colors
curl "${CURL_DOWNLOAD_OPTS[@]}" -o "$HOME/conky-convert.lua" \
    "https://raw.githubusercontent.com/brndnmtthws/conky/master/extras/convert.lua"
# conky-colors --help
conky-colors --theme=human --side=right --arch --cpu=2 --proc=5 \
    --swap --hd=mix --network --clock=modern --calendar
    # --weather=2161838 --bbcweather=1809858 --unit=C
# network interface
get_network_interface_default
[[ -n "${NETWORK_INTERFACE_DEFAULT}" ]] && \
    sed -i "s/ppp0/${NETWORK_INTERFACE_DEFAULT}/g" "$HOME/.conkycolors/conkyrc"
# display font
sed -i 's/font Liberation Sans/font Sarasa Term SC/g' "$HOME/.conkycolors/conkyrc" && \
    sed -i 's/font Liberation Mono/font Sarasa Mono SC/g' "$HOME/.conkycolors/conkyrc" && \
    sed -i 's/font ConkyColors/font Sarasa Term SC/g' "$HOME/.conkycolors/conkyrc" && \
    sed -i 's/font Sarasa Term SCLogos/font ConkyColorsLogos/g' "$HOME/.conkycolors/conkyrc" && \
    : && \
    lua "$HOME/conky-convert.lua" "$HOME/.conkycolors/conkyrc"
# conky -c "$HOME/.conkycolors/conkyrc"

# Hybrid
# https://bitbucket.org/dirn-typo
Git_Clone_Update_Branch "https://bitbucket.org/dirn-typo/hybrid.git" "$HOME/.conky/hybrid"
if [[ -d "$HOME/.conky/hybrid" ]]; then
    chmod +x "$HOME/.conky/hybrid/install.sh"
    "$HOME/.conky/hybrid/install.sh"

    cp -f "$HOME/.conky/hybrid/fonts/"* "$HOME/.local/share/fonts/"
    fc-cache -fv
fi

if [[ -s "$HOME/.config/conky/hybrid/hybrid.conf" ]]; then
    sed -i "s|home_dir = .*|home_dir = \"${HOME}\"|" "$HOME/.config/conky/hybrid/lua/hybrid-rings.lua"

    # monitor the temperature of CPU & GPU
    # https://askubuntu.com/questions/1322971/temperature-sensors-hwmon5-and-hwmon6-keep-swapping-around-how-can-i-consistent
    # ls -la /sys/class/hwmon/
    # https://bbs.archlinux.org/viewtopic.php?id=242492
    # echo /sys/devices/platform/*/hwmon/hwmon*
    sed -i "s|name='platform',|name='hwmon',|g" "$HOME/.config/conky/hybrid/lua/hybrid-rings.lua"
    sed -i "s|pt.name == 'platform'|pt.name == 'platform' or pt.name == 'hwmon'|g" "$HOME/.config/conky/hybrid/lua/hybrid-rings.lua"

    CPU_HWMON_DEVICE=$(echo /sys/devices/platform/*/hwmon/hwmon* | head -n1 | awk -F"/" '{print $NF}')
    [[ -f "/sys/class/hwmon/${CPU_HWMON_DEVICE}/name" ]] && \
        CPU_HWMON_NAME=$(< "/sys/class/hwmon/${CPU_HWMON_DEVICE}/name")

    [[ -n "${CPU_HWMON_NAME}" ]] && \
        sed -i "s|coretemp.0/hwmon/hwmon5|${CPU_HWMON_NAME}|g" "$HOME/.config/conky/hybrid/lua/hybrid-rings.lua"

    sed -i -e 's/own_window_transparent.*/own_window_transparent = false,/' \
        -e 's/minimum_width.*/minimum_width = 550,/' \
        -e 's/font NotoSans/font Sarasa Term SC/g' \
        -e 's/time %A %d %b %Y/time %Y年%b%-d日 %A 第%W周/g' "$HOME/.config/conky/hybrid/hybrid.conf"

    [[ -n "${NETWORK_INTERFACE_DEFAULT}" ]] && \
        sed -i "s/enp7s0f1/${NETWORK_INTERFACE_DEFAULT}/g" "$HOME/.config/conky/hybrid/hybrid.conf"
fi

## conky-weather
## https://github.com/kuiba1949/conky-weather
# Git_Clone_Update_Branch "kuiba1949/conky-weather" "$HOME/.conky/conky-weather"
# if [[ -d "$HOME/.conky/conky-weather" ]]; then
#     sed -i 's/alignment top_right/alignment middle_middle/' "$HOME/.conky/conky-weather/conkyrc_mini" && \
#         sed -i 's/WenQuanYi Zen Hei/font Sarasa Term SC/g' "$HOME/.conky/conky-weather/conkyrc_mini" && \
#         sed -i 's/gap_y.*/gap_y 20/' "$HOME/.conky/conky-weather/conkyrc_mini" && \
#         sed -i 's/draw_borders.*/draw_borders = false,/' "$HOME/.conky/conky-weather/conkyrc_mini" && \
#         sed -i '/own_window_colour/,$d' "$HOME/.conky/conky-weather/conkyrc_mini" && \
#         : && \
#         lua "$HOME/conky-convert.lua" "$HOME/.conky/conky-weather/conkyrc_mini" && \
#         : && \
#         cd "$HOME/.conky/conky-weather/bin" && \
#         chmod +x ./conky-weather-update &&\
#         ./conky-weather-update && \
#         : && \
#         sed -i "s|Exec=.*|Exec=$HOME/.conky/conky-weather/bin/conky-weather-update|" \
#             "$HOME/.config/autostart/86conky-weather-update.desktop"
#         # sed -i '/提醒/,$d' "$HOME/.conky/conky-weather/conkyrc_mini"
# fi

# A Conky theme pack
# https://github.com/closebox73/Leonis
Git_Clone_Update_Branch "closebox73/Leonis" "$HOME/.conky/Leonis"
if [[ -d "$HOME/.conky/Leonis/Regulus" ]]; then
    cp -r "$HOME/.conky/Leonis/Regulus/" "$HOME/.conky/"

    sed -i 's|~/.config/conky/|~/.conky/|g' "$HOME/.conky/Regulus/Regulus.conf"
    [[ -n "${NETWORK_INTERFACE_DEFAULT}" ]] && \
        sed -i "s/wlp9s0/${NETWORK_INTERFACE_DEFAULT}/g" "$HOME/.conky/Regulus/Regulus.conf"

    # export OpenWeatherMap_Key="" && export OpenWeatherMap_CityID="" && OpenWeatherMap_LANG="zh_cn"
    [[ -n "$OpenWeatherMap_Key" ]] && \
        sed -i "s/api_key=.*/api_key=${OpenWeatherMap_Key}/" "$HOME/.conky/Regulus/scripts/weather.sh"

    [[ -n "$OpenWeatherMap_CityID" ]] && \
        sed -i "s/city_id=.*/city_id=${OpenWeatherMap_CityID}/" "$HOME/.conky/Regulus/scripts/weather.sh"

    [[ -n "$OpenWeatherMap_LANG" ]] && \
        sed -i "s/lang=en/lang=${OpenWeatherMap_LANG}/" "$HOME/.conky/Regulus/scripts/weather.sh"
fi

# Conky Showcase
# https://forum.manjaro.org/tag/conky
# Manjaro logo: /usr/share/icons/logo_green.png

# Minimalis
# https://www.gnome-look.org/p/1112273/

# Sci-Fi HUD
# https://www.gnome-look.org/p/1197920/

## Custom Conky Themes for blackPanther OS
## https://github.com/blackPantherOS/Conky-themes
# Git_Clone_Update_Branch "blackPantherOS/Conky-themes" "$HOME/.conky/blackPantherOS"

# # Aureola: A conky collection of great conky's following the lua syntax
# # https://github.com/erikdubois/Aureola
# git clone --depth 1 https://github.com/erikdubois/Aureola "$HOME/conky-theme-aureola"
# cd "$HOME/conky-theme-aureola" && ./get-aureola-from-github-to-local-drive-v1.sh
# cd "$HOME/.aureola/lazuli" && ./install-conky.sh

# # conky-ubuntu
# # https://fanqxu.com/2019/04/03/conky-ubuntu/
# # echo "$HOME/.config/conky/startconky.sh &" >> "$HOME/.xprofile"
# git clone https://github.com/FanqXu/conkyrc "$HOME/.conky/conky-ubuntu" && \
#     cd "$HOME/.conky/conky-ubuntu" && \
#     ./install.sh

# # Harmattan
# # https://github.com/zagortenay333/Harmattan
# git clone --depth=1 https://github.com/zagortenay333/Harmattan "$HOME/Harmattan" && \
#     cp -rf "$HOME/Harmattan/.harmattan-assets" "$HOME"
# # cd Harmattan && ./preview

# # set conky theme
# cp -f "$HOME/Harmattan/.harmattan-themes/Numix/God-Mode/normal-mode/.conkyrc" "$HOME"

# # postions
# sed -i 's/--alignment="middle_middle",/alignment="top_right",/' "$HOME/.conkyrc" && \
#     sed -i 's/gap_x.*/gap_x=10,/' "$HOME/.conkyrc" && \
#     sed -i 's/gap_y.*/gap_y=100,/' "$HOME/.conkyrc"

# # settings
# get_network_interface_default

# colorEchoN "${ORANGE}[OpenWeatherMap Api Key? "
# read -r OpenWeatherMap_Key
# colorEchoN "${ORANGE}OpenWeatherMap City ID? "
# read -r OpenWeatherMap_CityID
# colorEchoN "${ORANGE}OpenWeatherMap LANG?[${CYAN}zh_cn${ORANGE}]: "
# read -r OpenWeatherMap_LANG
# [[ -z "$OpenWeatherMap_LANG" ]] && OpenWeatherMap_LANG="zh_cn"

# sed -i 's/template6=\"\"/template6=\"${OpenWeatherMap_Key}\"/g' "$HOME/.conkyrc" && \
#     sed -i 's/template7=\"\"/template7=\"${OpenWeatherMap_CityID}\"/g' "$HOME/.conkyrc" && \
#     sed -i 's/ppp0/${NETWORK_INTERFACE_DEFAULT}/g' "$HOME/.conkyrc"

# # star script
# cat > "$HOME/.conky/start.sh" <<-EOF
# #!/usr/bin/env bash
# killall conky
# apiKey=${OpenWeatherMap_Key}
# cityId=${OpenWeatherMap_CityID}
# unit=metric
# lang=${OpenWeatherMap_LANG}
# curl -fsSL "api.openweathermap.org/data/2.5/forecast?id=\${cityId}&cnt=5&units=\${unit}&appid=\${apiKey}&lang=\${lang}" -o "$HOME/.cache/harmattan-conky/forecast.json"
# curl -fsSL "api.openweathermap.org/data/2.5/weather?id=\${cityId}&cnt=5&units=\${unit}&appid=\${apiKey}&lang=\${lang}" -o "$HOME/.cache/harmattan-conky/weather.json"
# sleep 2
# conky 2>/dev/null &
# EOF

# auto start conky
cat > "$HOME/.conky/autostart.sh" <<-EOF
#!/usr/bin/env bash

killall conky conky

# time (in s) for the DE to start; use ~20 for Gnome or KDE, less for Xfce/LXDE etc
sleep 10

## the main conky
## /usr/share/conkycolors/bin/conkyStart

# conky -c "$HOME/.conkycolors/conkyrc" --daemonize --quiet
conky -c "$HOME/.config/conky/hybrid/hybrid.conf" --daemonize --quiet

# time for the main conky to start
# needed so that the smaller ones draw above not below 
# probably can be lower, but we still have to wait 5s for the rings to avoid segfaults
# sleep 5

# conky -c "$HOME/.conky/conky-weather/conkyrc_mini" --daemonize --quiet
EOF

chmod +x "$HOME/.conky/autostart.sh"

if ! grep -q "autostart.sh" "$HOME/.xprofile" 2>/dev/null; then
    echo -e "\n# conky" >> "$HOME/.xprofile"
    echo "$HOME/.conky/autostart.sh >/dev/null 2>&1 & disown" >> "$HOME/.xprofile"
fi

# mkdir -p "$HOME/.config/autostart"
# cat > "$HOME/.config/autostart/conky-colors.desktop" <<-EOF
# [Desktop Entry]
# Name=conky-colors
# Exec=/usr/share/conkycolors/bin/conkyStart
# Type=Application
# Terminal=false
# Hidden=false
# NoDisplay=false
# StartupNotify=false
# EOF

# cat > "$HOME/.config/autostart/conky-weather.desktop" <<-EOF
# [Desktop Entry]
# Name=conky-weather
# Exec=conky -c "$HOME/.conky/conky-weather/conkyrc_mini" --daemonize --quiet
# Type=Application
# Terminal=false
# Hidden=false
# NoDisplay=false
# StartupNotify=false
# EOF

# Change from exfat-utils to exfatprogs for exfat
yay --needed -S exfatprogs

# Desktop
sudo pacman --noconfirm --needed -S dmenu

# compton: X compositor that may fix tearing issues
# feh: Fast and light imlib2-based image viewer
# inkscape: Professional vector graphics editor
# mate-power-manager: Power management tool for the MATE desktop
# mpd: Flexible, powerful, server-side application for playing music
# ncmpcpp: Fully featured MPD client using ncurses
# polybar: A fast and easy-to-use status bar
# scrot: command-line screenshot utility for X
# xcompmgr: Composite Window-effects manager for X.org
sudo pacman --noconfirm --needed -S compton feh inkscape mate-power-manager mpd ncmpcpp polybar scrot

# # xmonad https://xmonad.org/
# # sudo pacman --noconfirm --needed -S xmonad xmonad-contrib xmonad-utils slock xmobar

# # i3 https://i3wm.org/
# # https://www.zhihu.com/question/62251457
# # https://github.com/levinit/i3wm-config
# # https://github.com/Karmenzind/dotfiles-and-scripts/
# # i3-gaps i3-wm i3blocks i3lock i3status
# sudo pacman --noconfirm --needed -S i3
# sudo pacman --noconfirm --needed -S i3-scrot i3lock-color betterlockscreen
# sudo pacman --noconfirm --needed -S i3-scripts i3-theme-dark i3-theme-dust i3-wallpapers
# # artwork-i3 conky-i3 dmenu-manjaro i3-default-artwork i3-help
# # i3exit i3status-manjaro manjaro-i3-settings manjaro-i3-settings-bldbk
# sudo pacman --noconfirm --needed -S i3-manjaro

# # DWM
# # https://wiki.archlinux.org/index.php/Dwm_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
# # https://github.com/GoDzM4TT3O/dotfiles
# git clone --recurse-submodules https://github.com/GoDzM4TT3O/dotfiles && \
#     cd dotfiles && \
#     cp -r .{config,vim*,z*,x*,X*,alias*,p10k.zsh,local} $HOME && \
#     cp -r dwm $HOME

# # Rofi: A window switcher, Application launcher and dmenu replacement
# # https://github.com/davatorium/rofi
# # https://github.com/adi1090x/rofi

# # powerline: Statusline plugin for vim, and provides statuslines and prompts for several other applications, 
# # including zsh, bash, tmux, IPython, Awesome, i3 and Qtile
# sudo pacman --noconfirm --needed -S powerline


# Apps
# Broswer
sudo pacman --noconfirm --needed -S chromium
yay --noconfirm --needed -S google-chrome
# yay --noconfirm --needed -S google-chrome-beta
# yay --noconfirm --needed -S google-chrome-dev
# yay --noconfirm --needed -S microsoft-edge-stable-bin

# Clipborad
sudo pacman --noconfirm --needed -S copyq

# Develop
sudo pacman --noconfirm --needed -S dbeaver wireshark-qt
yay --noconfirm --needed -S visual-studio-code-bin

# Dictionary
# sudo pacman --noconfirm --needed -S goldendict-git

# Download & Upload
sudo pacman --noconfirm --needed -S aria2 motrix you-get filezilla

# Docker
sudo pacman --noconfirm --needed -S docker docker-compose
# yay -S kitematic

# File & dir compare
sudo pacman --noconfirm --needed -S meld

# Free disk space and maintain privacy
sudo pacman --noconfirm --needed -S bleachbit

# IM
yay --noconfirm --needed -S telegram-desktop linuxqq deepin-wine-qq deepin-wine-wechat wemeet-bin
# yay --noconfirm --needed -S deepin-wine-tim

# Markdown
sudo pacman --noconfirm --needed -S vnote-git
# sudo pacman --noconfirm --needed -S typora

# Note
# yay --noconfirm --needed -S leanote
# sudo pacman --noconfirm --needed -S wiznote
# sudo pacman --noconfirm --needed -S cherrytree

# Netdisk
yay --noconfirm --needed -S baidunetdisk-bin

# Password manager
sudo pacman --noconfirm --needed -S enpass keepass bitwarden

# PDF Reader
sudo pacman --noconfirm --needed -S evince
# yay --noconfirm --needed -S foxitreader

# Player
sudo pacman --noconfirm --needed -S netease-cloud-music
sudo pacman --noconfirm --needed -S smplayer smplayer-skins smplayer-themes
# yay --noconfirm --needed -S qqmusic-bin

# Proxy
# sudo pacman --noconfirm --needed -S proxychains-ng v2ray
sudo pacman --noconfirm --needed -S frps frpc

# Screenshot
sudo pacman --noconfirm --needed -S deepin-screenshot flameshot
# sudo pacman --noconfirm --needed -S xfce4-screenshooter

# Search
sudo pacman --noconfirm --needed -S synapse utools
yay --noconfirm --needed -S albert-bin

# Linux Advanced Power Management
sudo pacman --noconfirm --needed -S tlp tlp-rdw tlpui
sudo tlp start
# sudo tlp-stat -s # System Info
# sudo tlp-stat -b # Battery Care

# System
sudo pacman --noconfirm --needed -S btop font-manager filelight peek redshift ventoy-bin
# yay --noconfirm --needed -S easystroke

# Terminal
# sudo pacman --noconfirm --needed -S konsole

# Virtualbox
yay --noconfirm --needed -S aur/virtualbox-bin
yay --noconfirm --needed -S aur/virtualbox-ext-oracle

# WPS
yay --noconfirm --needed -S wps-office-cn wps-office-mui-zh-cn wps-office-mime-cn
yay --noconfirm --needed -S wps-office-fonts ttf-wps-fonts wps-office-all-dicts-win-languages

# # eDEX-UI
# # https://github.com/GitSquared/edex-ui
# # yay --noconfirm --needed -S edex-ui-git
# CHECK_URL="https://api.github.com/repos/GitSquared/edex-ui/releases/latest"
# REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty')
# wget -c -O eDEX-UI.AppImage \
#     https://github.com/GitSquared/edex-ui/releases/download/${REMOTE_VERSION}/eDEX-UI.Linux.x86_64.AppImage


# # pyenv
# # https://segmentfault.com/a/1190000006174123
# sudo pacman --noconfirm --needed -S pyenv

# pyenv init
# pyenv install --list
# pyenv install <version>
# v=3.9.8;wget https://npmmirror.com/mirrors/python/$v/Python-$v.tar.xz -P ~/.pyenv/cache/;pyenv install $v
# pyenv versions
# pyenv uninstall <version>
# pyenv global <version>


# # penetration testing
# sudo pacman --noconfirm --needed -S metasploit msfdb nmap hydra sqlmap
# sudo msfdb-blackarch init
# sudo msfdb-blackarch start


# KVM & QEMU
# https://wiki.archlinux.org/title/QEMU
# https://getlabsdone.com/how-to-install-windows-11-on-kvm/
# emulate the TPM
sudo pacman --noconfirm --needed -S swtpm
# Enable secure-boot/UEFI on KVM
sudo pacman --noconfirm --needed -S edk2-ovmf
# Install the qemu package
sudo pacman --noconfirm --needed -S qemu
sudo pacman --noconfirm --needed -S libvirt virt-install virt-manager virt-viewer
sudo systemctl enable libvirtd && sudo systemctl start libvirtd

# ISO image at: /var/lib/libvirt/images
sudo pacman --noconfirm --needed -S virtio-win

## SPICE
## spice-guest-tools
## https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe
## spice-webdavd
## https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x64-latest.msi
# sudo virt-viewer

## Shared folder
## https://techpiezo.com/linux/shared-folder-in-qemu-virtual-machine-windows/
# qemu-system-x86_64 -net nic -net user,smb=<shared_folder_path> ...
## Custom Network Location: \\10.0.2.4\qemu\

## Add physical disk to kvm virtual machine
# sudo env EDITOR=nano virsh edit [name_of_vm]

## Interacting with virtual machines
## https://libvirt.org/manpages/virsh.html
# sudo virsh nodeinfo
# sudo virsh list --all
# sudo virsh domxml-to-native qemu-argv --domain [name_of_vm]
# sudo virsh domblklist [name_of_vm]
# sudo virsh start [name_of_vm]
# sudo virsh shutdown [name_of_vm]

## network
# brctl show
# sudo virsh net-list --all
# sudo virsh net-info default
# sudo virsh net-dumpxml default

## Create a new libvirt network
## https://kashyapc.fedorapeople.org/virt/create-a-new-libvirt-bridge.txt
# virsh net-define [new_name_of_network].xml

## Marked network default as autostarted
# sudo virsh net-autostart default
# sudo virsh net-start default

## remove the network named default
# sudo virsh net-autostart default --disable
# sudo virsh net-destroy default
# sudo virsh net-undefine default

## autostart vm
# sudo virsh autostart [name_of_vm]

## To destroy or forcefully power off virtual machine
# sudo virsh destroy [name_of_vm]

## To delete or removing virtual machine along with its disk file
## a) First shutdown the virtual machine
# sudo virsh shutdown [name_of_vm]
## b) Delete the virtual machine along with its associated storage file
# sudo virsh undefine [name_of_vm] --nvram –remove-all-storage

## rename KVM domain
# sudo virsh shutdown [name_of_vm]
# sudo virsh domrename [name_of_vm] [new_name_of_vm]
## or
# sudo virsh dumpxml [name_of_vm] > [new_name_of_vm].xml
## Edit the XML file and change the name between the <name></name>
# sudo virsh shutdown [name_of_vm]
# sudo virsh undefine [name_of_vm] --nvram
## import the edited XML file to define the VM bar
# sudo virsh define [new_name_of_vm].xml

## Snapshot
# sudo virsh snapshot-create-as -–domain [name_of_vm] --name "name_of_snapshot" --description "description_of_snapshot"
# sudo virsh snapshot-list [name_of_vm]
# sudo virsh snapshot-revert --doamin [name_of_vm] --snapshotname "name_of_snapshot" --running
# sudo virsh snapshot-delete --doamin [name_of_vm] --snapshotname "name_of_snapshot"

## Reduce the size of VM files
## https://pov.es/virtualisation/kvm/kvm-qemu-reduce-the-size-of-your-vm-files/
## Stop the VM and then process the VM file
# sudo qemu-img info /var/lib/libvirt/images/[name_of_vm].qcow2
# sudo qemu-img convert -O qcow2 /var/lib/libvirt/images/[name_of_vm].qcow2 /var/lib/libvirt/images/[name_of_vm]-compressed.qcow2
## An alternative way of reducing the VM size is by using virt-sparsify
# yay --noconfirm --needed -S flex guestfs-tools
# sudo virt-sparsify --in-place /var/lib/libvirt/images/[name_of_vm].qcow2

## Run Windows apps
## https://github.com/Osmium-Linux/winapps
# Git_Clone_Update_Branch "Osmium-Linux/winapps" "$HOME/winapps"

## Set up KVM to run as your user instead of root and allow it through AppArmor
# sudo sed -i "s/#user = \"root\"/user = \"$(id -un)\"/g" "/etc/libvirt/qemu.conf"
# sudo sed -i "s/#group = \"root\"/group = \"$(id -gn)\"/g" "/etc/libvirt/qemu.conf"
# sudo usermod -a -G kvm "$(id -un)"
# sudo usermod -a -G libvirt "$(id -un)"
# sudo systemctl restart libvirtd
## sudo ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
# sleep 5
# # Marked network default as autostarted
# sudo virsh net-autostart default
# sudo virsh net-start default

# mkdir -p "$HOME/.config/winapps/"
# tee "$HOME/.config/winapps/winapps.conf" >/dev/null <<-EOF
# RDP_USER="MyWindowsUser"
# RDP_PASS="MyWindowsPassword"
# #RDP_DOMAIN="MYDOMAIN"
# #RDP_IP="192.168.123.111"
# #RDP_SCALE=100
# #RDP_FLAGS=""
# #MULTIMON="true"
# #DEBUG="true"
# #VIRT_MACHINE_NAME="machine-name"
# #VIRT_NEEDS_SUDO="true"
# #RDP_SECRET="account"
# EOF

## add the RDP password for lookup using secret tool
# secret-tool store --label='winapps' winapps account

# if [[ -d "$HOME/winapps" ]]; then
#     cd "$HOME/winapps" && bin/winapps check
#     ./installer.sh --user
# fi


# Clean jobs
# sudo pacman -Rns $(pacman -Qtdq)
yay -Yc


# Auto shutdown at 20:00
# (crontab -l 2>/dev/null || true; echo "0 20 * * * sync && shutdown -h now") | crontab -


## Reset curl proxy
# if [[ "$CURL_PROXY_CHOICE" == 'y' || "$CURL_PROXY_CHOICE" == 'Y' ]]; then
#     colorEchoN "${ORANGE}Reset curl socks5 proxy?[${CYAN}Y${ORANGE}/n]: "
#     read -r CHOICE
#     [[ -z "$CHOICE" ]] && CHOICE=Y
#     if [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]]
#         sed -i "/^--socks5-hostname.*/d" "$HOME/.curlrc"
#     fi
# fi


cd "${CURRENT_DIR}" || exit
colorEcho "${GREEN}Done!"
