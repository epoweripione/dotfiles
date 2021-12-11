#!/usr/bin/env bash

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
    sudo pacman --noconfirm -Syy && \
        sudo pacman --noconfirm -S archlinuxcn-keyring && \
        sudo pacman --noconfirm -S archlinuxcn-mirrorlist-git
fi

# Full update
sudo pacman --noconfirm -Syu


# Language packs
sudo pacman --noconfirm -S \
    firefox-i18n-zh-cn thunderbird-i18n-zh-cn gimp-help-zh_cn \
    libreoffice-still-zh-CN man-pages-zh_cn


# sshd
[[ $(systemctl is-enabled sshd 2>/dev/null) ]] || \
    { sudo systemctl enable sshd; sudo systemctl start sshd; }


# Virtualbox
# https://wiki.manjaro.org/index.php?title=VirtualBox
# https://forum.manjaro.org/t/howto-virtualbox-installation-usb-shared-folders/55905
# virtualbox-guest-utils
colorEchoN "${ORANGE}Install virtualbox-guest-utils?[y/${CYAN}N${ORANGE}]: "
read -r CHOICE
if [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]]; then
    sudo pacman --noconfirm -S virtualbox-guest-utils
    linux_ver=linux$(uname -r | cut -d'.' -f1-2 | sed 's/\.//')
    sudo pacman --noconfirm -S "${linux_ver}-virtualbox-guest-modules"
fi


# winbind
colorEchoN "${ORANGE}Enable winbind?[y/${CYAN}N${ORANGE}]: "
read -r CHOICE
if [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]]; then
    sudo pacman --noconfirm -S manjaro-settings-samba
    sudo usermod -a -G sambashare "$(whoami)"
    sudo systemctl enable winbind && sudo systemctl start winbind
fi


# pre-requisite packages
colorEcho "${BLUE}Installing ${FUCHSIA}pre-requisite packages${BLUE}..."
sudo pacman --noconfirm -S git curl wget unzip


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
colorEcho "${BLUE}Installing ${FUCHSIA}yay${BLUE}..."
if [[ -d "$HOME/yay" ]]; then
    cd "$HOME/yay" && git pull && makepkg -si
else
    Git_Clone_Update_Branch "yay" "$HOME/yay" "https://aur.archlinux.org/"
    [[ -d "$HOME/yay" ]] && cd "$HOME/yay" && makepkg -si
fi

## AUR mirror in china
# if ! check_webservice_up www.google.com; then
if [[ "$IP_GEO_IN_CHINA" == "yes" ]]; then
    # ~/.config/yay/config.json
    # yay -P -g
    [[ -x "$(command -v yay)" ]] && \
        yay --aururl "https://aur.tuna.tsinghua.edu.cn" --save
fi


# Fonts
sudo pacman --noconfirm -S powerline-fonts ttf-symbola ttf-fira-code ttf-sarasa-gothic \
    ttf-hannom noto-fonts noto-fonts-extra noto-fonts-emoji noto-fonts-cjk

# sudo pacman --noconfirm -S ttf-dejavu ttf-droid ttf-hack ttf-font-awesome otf-font-awesome \
#     ttf-lato ttf-liberation ttf-linux-libertine ttf-opensans ttf-roboto ttf-ubuntu-font-family

# sudo pacman --noconfirm -S adobe-source-code-pro-fonts adobe-source-sans-fonts adobe-source-serif-fonts \
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
    sudo chmod -R 744 "/usr/share/fonts/FiraCode-Mono" && \
    sudo fc-cache -fv


## Fcitx input methods for Chinese Pinyin
# yay --noconfirm -S qtwebkit-bin fcitx-qt4
# yay --noconfirm -S fcitx fcitx-im fcitx-rime fcitx-configtool
# yay --noconfirm -S fcitx-cloudpinyin fcitx-googlepinyin 
# yay --noconfirm -S fcitx-skin-material
# yay --noconfirm -S fcitx-sogoupinyin

# Fcitx5 input methods for Chinese Pinyin
# https://github.com/fcitx/fcitx5
# https://blog.rasphino.cn/archive/a-taste-of-fcitx5-in-arch.html
sudo pacman --noconfirm -Rs "$(pacman -Qsq fcitx)"
sudo pacman --noconfirm -S fcitx5 fcitx5-configtool fcitx5-qt fcitx5-gtk fcitx5-material-color
sudo pacman --noconfirm -S fcitx5-im fcitx-sunpinyin fcitx5-chinese-addons fcitx5-pinyin-zhwiki

tee -a "$HOME/.pam_environment" >/dev/null <<-'EOF'
# fcitx
GTK_IM_MODULE DEFAULT=fcitx
QT_IM_MODULE  DEFAULT=fcitx
XMODIFIERS    DEFAULT=\@im=fcitx
SDL_IM_MODULE DEFAULT=fcitx
EOF

tee -a "$HOME/.xprofile" >/dev/null <<-'EOF'
# fcitx5
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
export SDL_IM_MODULE=fcitx

# auto start fcitx5
fcitx5 &
EOF

# fcitx5 theme
# https://github.com/hosxy/Fcitx5-Material-Color
mkdir -p "$HOME/.config/fcitx5/conf"
tee -a "$HOME/.config/fcitx5/conf/classicui.conf" >/dev/null <<-'EOF'
Vertical Candidate List=False
PerScreenDPI=True
Font="更纱黑体 SC Medium 13"

Theme=Material-Color-Blue
EOF


# RDP Server
# http://www.xrdp.org/
# https://wiki.archlinux.org/index.php/xrdp
sudo pacman --noconfirm -S xrdp
# yay --noconfirm -S xorgxrdp xrdp
echo 'allowed_users=anybody' | sudo tee -a /etc/X11/Xwrapper.config
sudo systemctl enable xrdp xrdp-sesman && \
    sudo systemctl start xrdp xrdp-sesman


# RDP Client
sudo pacman --noconfirm -S freerdp remmina


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


# # Conky
# sudo pacman --noconfirm -S conky
sudo pacman --noconfirm -S conky-lua-nv conky-manager jq lua-clock-manjaro

# conky-colors
# https://github.com/helmuthdu/conky_colors
# http://forum.ubuntu.org.cn/viewtopic.php?f=94&t=313031
# http://www.manongzj.com/blog/4-lhjnjqtantllpnj.html
yay --noconfirm -S conky-colors
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

# conky-weather
# https://github.com/kuiba1949/conky-weather
Git_Clone_Update_Branch "kuiba1949/conky-weather" "$HOME/.conky/conky-weather"
if [[ -d "$HOME/.conky/conky-weather" ]]; then
    sed -i 's/alignment top_right/alignment middle_middle/' "$HOME/.conky/conky-weather/conkyrc_mini" && \
        sed -i 's/WenQuanYi Zen Hei/font Sarasa Term SC/g' "$HOME/.conky/conky-weather/conkyrc_mini" && \
        sed -i 's/gap_y.*/gap_y 20/' "$HOME/.conky/conky-weather/conkyrc_mini" && \
        sed -i 's/draw_borders.*/draw_borders = false,/' "$HOME/.conky/conky-weather/conkyrc_mini" && \
        sed -i '/own_window_colour/,$d' "$HOME/.conky/conky-weather/conkyrc_mini" && \
        : && \
        lua "$HOME/conky-convert.lua" "$HOME/.conky/conky-weather/conkyrc_mini" && \
        : && \
        cd "$HOME/.conky/conky-weather/bin" && \
        chmod +x ./conky-weather-update &&\
        ./conky-weather-update && \
        : && \
        sed -i "s|Exec=.*|Exec=$HOME/.conky/conky-weather/bin/conky-weather-update|" \
            "$HOME/.config/autostart/86conky-weather-update.desktop"
        # sed -i '/提醒/,$d' "$HOME/.conky/conky-weather/conkyrc_mini"
fi

# Custom Conky Themes for blackPanther OS
# https://github.com/blackPantherOS/Conky-themes
Git_Clone_Update_Branch "blackPantherOS/Conky-themes" "$HOME/.conky/blackPantherOS"

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

killall conky

# time (in s) for the DE to start; use ~20 for Gnome or KDE, less for Xfce/LXDE etc
sleep 10

# the main conky
# /usr/share/conkycolors/bin/conkyStart
conky -c "$HOME/.conkycolors/conkyrc" --daemonize --quiet

# time for the main conky to start
# needed so that the smaller ones draw above not below 
# probably can be lower, but we still have to wait 5s for the rings to avoid segfaults
sleep 5

conky -c "$HOME/.conky/conky-weather/conkyrc_mini" --daemonize --quiet
EOF

chmod +x "$HOME/.conky/autostart.sh"
if ! grep -q "autostart.sh" "$HOME/.xprofile" 2>/dev/null; then
    # echo "$HOME/.conky/autostart.sh &" >> "$HOME/.xprofile"
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


# # Desktop
sudo pacman --noconfirm -S dmenu

# compton: X compositor that may fix tearing issues
# feh: Fast and light imlib2-based image viewer
# inkscape: Professional vector graphics editor
# mate-power-manager: Power management tool for the MATE desktop
# mpd: Flexible, powerful, server-side application for playing music
# ncmpcpp: Fully featured MPD client using ncurses
# polybar: A fast and easy-to-use status bar
# scrot: command-line screenshot utility for X
# xcompmgr: Composite Window-effects manager for X.org
sudo pacman --noconfirm -S compton feh inkscape mate-power-manager mpd ncmpcpp polybar scrot

# # xmonad https://xmonad.org/
# # sudo pacman --noconfirm -S xmonad xmonad-contrib xmonad-utils slock xmobar

# # i3 https://i3wm.org/
# # https://www.zhihu.com/question/62251457
# # https://github.com/levinit/i3wm-config
# # https://github.com/Karmenzind/dotfiles-and-scripts/
# # i3-gaps i3-wm i3blocks i3lock i3status
# sudo pacman --noconfirm -S i3
# sudo pacman --noconfirm -S i3-scrot i3lock-color betterlockscreen
# sudo pacman --noconfirm -S i3-scripts i3-theme-dark i3-theme-dust i3-wallpapers
# # artwork-i3 conky-i3 dmenu-manjaro i3-default-artwork i3-help
# # i3exit i3status-manjaro manjaro-i3-settings manjaro-i3-settings-bldbk
# sudo pacman --noconfirm -S i3-manjaro

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
# sudo pacman --noconfirm -S powerline


# Apps
# Broswer
sudo pacman --noconfirm -S google-chrome chromium

# Clipborad
sudo pacman --noconfirm -S copyq

# Develop
sudo pacman --noconfirm -S visual-studio-code-bin dbeaver wireshark-qt

# Dictionary
sudo pacman --noconfirm -S goldendict

# Download & Upload
sudo pacman --noconfirm -S aria2 uget filezilla

# Docker
sudo pacman --noconfirm -S docker docker-compose
# yay -S kitematic

# File & dir compare
sudo pacman --noconfirm -S meld

# Free disk space and maintain privacy
sudo pacman --noconfirm -S bleachbit

# IM
yay --noconfirm -S qq-linux
sudo pacman --noconfirm -S electronic-wechat telegram-desktop
# yay --noconfirm -S eepin.com.qq.im deepin.com.qq.office
# yay --noconfirm -S deepin-wine-wechat deepin-wine-tim deepin-wine-qq electronic-wechat-bin

# Markdown
sudo pacman --noconfirm -S vnote-git
# sudo pacman --noconfirm -S typora

# Note
sudo pacman --noconfirm -S leanote
# sudo pacman --noconfirm -S wiznote
# yay --noconfirm -S cherrytree

# Password manager
sudo pacman --noconfirm -S enpass-bin

# PDF Reader
sudo pacman --noconfirm -S evince foxitreader

# Player
sudo pacman --noconfirm -S netease-cloud-music
# sudo pacman --noconfirm -S smplayer smplayer-skins smplayer-themes

# Proxy
# sudo pacman --noconfirm -S proxychains-ng v2ray

# Screenshot
sudo pacman --noconfirm -S deepin-screenshot
# sudo pacman --noconfirm -S xfce4-screenshooter

# Search
sudo pacman --noconfirm -S albert synapse

# System
sudo pacman --noconfirm -S filelight gotop easystroke peek redshift

# Terminal
sudo pacman --noconfirm -S konsole

# WPS
sudo pacman --noconfirm -S wps-office ttf-wps-fonts wps-office-mui-zh-cn

# # eDEX-UI
# # https://github.com/GitSquared/edex-ui
# # yay --noconfirm -S edex-ui-git
# CHECK_URL="https://api.github.com/repos/GitSquared/edex-ui/releases/latest"
# REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | grep 'tag_name' | cut -d\" -f4)
# wget -c -O eDEX-UI.AppImage \
#     https://github.com/GitSquared/edex-ui/releases/download/${REMOTE_VERSION}/eDEX-UI.Linux.x86_64.AppImage


# pyenv
# https://segmentfault.com/a/1190000006174123
sudo pacman -S pyenv
# pyenv init
# pyenv install --list
# pyenv install <version>
# v=3.9.8;wget https://npmmirror.com/mirrors/python/$v/Python-$v.tar.xz -P ~/.pyenv/cache/;pyenv install $v
# pyenv versions
# pyenv uninstall <version>
# pyenv global <version>


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
