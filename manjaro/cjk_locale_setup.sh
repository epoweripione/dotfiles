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

[[ -z "${OS_INFO_DESKTOP}" ]] && get_os_desktop

# Fonts & Input Methods for CJK locale
# https://wiki.archlinux.org/title/Localization/Chinese
# default locale settings: /etc/locale.conf

# Use en_US.UTF-8 for terminal
# https://blog.flowblok.id.au/2013-02/shell-startup-scripts.html
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

# [Fonts](https://wiki.archlinux.org/title/fonts)
colorEcho "${BLUE}Installing ${FUCHSIA}fonts${BLUE}..."
if [[ -z "${FontManjaroInstallList[*]}" ]]; then
    FontManjaroInstallList=(
        # [Font Manager](https://github.com/FontManager/font-manager)
        "font-manager"
        "powerline-fonts"
        "ttf-fira-code"
        "ttf-firacode-nerd"
        # "ttf-font-awesome"
        "ttf-sarasa-gothic"
        "ttf-hannom"
        "noto-fonts"
        "noto-fonts-extra"
        "noto-fonts-cjk"
        "ttf-nerd-fonts-symbols"
        "ttf-nerd-fonts-symbols-mono"
        "ttf-iosevka-term"
        "ttf-jetbrains-mono"
        "ttf-jetbrains-mono-nerd"
        "ttf-lato"
        "ttf-lora-cyrillic"
        "ttf-lxgw-neo-xihei-screen"
        "ttf-lxgw-neo-xihei"
        "ttf-lxgw-wenkai-screen"
        "ttf-lxgw-wenkai-tc"
        "ttf-lxgw-neo-xihei-screen-full"
        "ttf-lxgw-wenkai"
        "ttf-lxgw-zhisong"
        "ttf-lxgw-xihei"
        "ttf-lxgw-wenkai-lite"
        "ttf-lxgw-wenkai-mono-lite"
        "ttf-lxgw-wenkai-gb"
        "ttf-lxgw-neo-zhisong"
        "ttf-lxgw-marker-gothic"
        # "ttf-lxgw-bright-git"
        # "ttf-lxgw-bright-tc-git"
        # "ttf-lxgw-bright-gb-git"
        # "ttf-lxgw-bright-code-git"
        # "ttf-lxgw-bright-code-tc-git"
        # "ttf-lxgw-bright-code-gb-git"
        "ttf-playfair-display"
        ## math
        "otf-latin-modern"
        "otf-cm-unicode"
        "otf-stix"
        ## emoji
        "archlinuxcn/ttf-twemoji"
        # "noto-fonts-emoji"
        # "unicode-emoji"
        ## Adobe fonts
        # "adobe-source-code-pro-fonts"
        # "adobe-source-sans-fonts"
        # "adobe-source-serif-fonts"
        # "adobe-source-han-sans-cn-fonts"
        # "adobe-source-han-sans-hk-fonts"
        # "adobe-source-han-sans-tw-fonts"
        # "adobe-source-han-serif-cn-fonts"
        ## WQY
        # "wqy-zenhei"
        # "wqy-microhei"
        ## Windows fonts
        # "ttf-ms-win11-auto"
        ## Other fonts
        # "ttf-dejavu"
        # "ttf-droid"
        # "ttf-hack"
        # "ttf-lato"
        # "ttf-liberation"
        # "ttf-linux-libertine"
        # "ttf-opensans"
        # "ttf-roboto"
        # "ttf-ubuntu-font-family"
    )
fi
InstallSystemPackages "" "${FontManjaroInstallList[@]}"

# emoji
# If you have other emoji fonts installed but want twemoji to always be used, make a symlink for twemojis font config:
# sudo ln -sf /usr/share/fontconfig/conf.avail/75-twemoji.conf /etc/fonts/conf.d/75-twemoji.conf
# You do not need to do this if you are fine with some apps using a different emoji font.
# If you do use other emoji fonts, copy 75-twemoji.conf to /etc/fonts/conf.d/ and remove corresponding aliases.
# To prevent conflicts with other emoji fonts, 75-twemoji.conf is not being automatically installed in /etc/fonts/conf.d/

# Microsoft Windows 11 TrueType fonts
colorEcho "${BLUE}Installing ${FUCHSIA}Microsoft Windows TrueType fonts${BLUE}..."
if [[ ! -d "/usr/share/fonts/WindowsFonts" ]]; then
    FontDownloadURL="https://github.com/epoweripione/fonts/releases/download/v0.1.0/ms-win11-fonts.zip"
    mkdir -p "${WORKDIR}/WindowsFonts" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/ms-win11-fonts.zip" "${FontDownloadURL}" && \
        unzip -q "${WORKDIR}/ms-win11-fonts.zip" -d "${WORKDIR}/WindowsFonts" && \
        sudo mkdir -p "/usr/share/fonts/WindowsFonts" && \
        sudo mv -f "${WORKDIR}/WindowsFonts/eastern/"*.* "/usr/share/fonts/WindowsFonts" && \
        sudo mv -f "${WORKDIR}/WindowsFonts/western/"*.* "/usr/share/fonts/WindowsFonts" && \
        sudo chmod -R 744 "/usr/share/fonts/WindowsFonts"
fi

## FiraCode Nerd Font Mono
[[ -d "/usr/share/fonts/FiraCode-Mono" ]] && sudo rm "/usr/share/fonts/FiraCode-Mono"
# colorEcho "${BLUE}Installing ${FUCHSIA}FiraCode Nerd Font Mono${BLUE}..."
# if [[ ! -d "/usr/share/fonts/FiraCode-Mono" ]]; then
#     App_Installer_Reset
#     INSTALLER_CHECK_URL="https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
#     App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"

#     # FontDownloadURL="https://github.com/epoweripione/fonts/releases/download/v0.1.0/FiraCode-Mono-6.2.0.zip"
#     if [[ -n "${INSTALLER_VER_REMOTE}" ]]; then
#         FontDownloadURL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${INSTALLER_VER_REMOTE}/FiraCode.zip"
#         mkdir -p "${WORKDIR}/FiraCode-Mono" && \
#             curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/FiraCode-Mono.zip" "${FontDownloadURL}" && \
#             unzip -q "${WORKDIR}/FiraCode-Mono.zip" -d "${WORKDIR}/FiraCode-Mono" && \
#             sudo mv -f "${WORKDIR}/FiraCode-Mono/" "/usr/share/fonts/" && \
#             sudo chmod -R 744 "/usr/share/fonts/FiraCode-Mono"
#     fi
# fi
# fc-list | grep "FiraCode" | column -t -s ":"

# DreamHanCJK, Pinyin & other fonts
FontInstallList=(
    "AlibabaHealthDesign"
    "DreamHanCJK"
    "MengshenPinyin"
    "ToneOZPinyinKai"
    "ToneOZPinyinWenkai"
    "ToneOZRadicalZ"
    "ToneOZTsuipita"
    "LXGWBright"
    "LXGWBrightCode"
    "LXGWKose"
    "LXGWNeoFusion"
    "LXGWNeoScreen"
    "LXGWNeoXiHeiCode"
    "LXGWYozai"
    # "MapleMono_hinted" # for low resolution screen(e.g. screen resolution is lower or equal than 1080P)
    "MapleMono_unhinted" # high resolution screen (e.g. 2K, 4K, Retina for MacBook)
)
for Target in "${FontInstallList[@]}"; do
    FontInstaller="${MY_SHELL_SCRIPTS}/fonts/${Target}_installer.sh"
    [[ ! -s "${FontInstaller}" ]] && FontInstaller="${MY_SHELL_SCRIPTS}/installer/${Target}_installer.sh"
    [[ -s "${FontInstaller}" ]] && source "${FontInstaller}"
done

# CJK fontconfig & colour emoji
# https://wiki.archlinux.org/title/Localization_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)/Simplified_Chinese_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
colorEcho "${BLUE}Setting ${FUCHSIA}CJK fontconfig & colour emoji${BLUE}..."
SYSTEM_LOCALE=$(localectl status | grep 'LANG=' | cut -d= -f2 | cut -d. -f1)
# if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cjk/fontconfig_alias_${SYSTEM_LOCALE}.xml" ]]; then
#     sudo cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cjk/fontconfig_alias_${SYSTEM_LOCALE}.xml" "/etc/fonts/local.conf"
# fi

## [用 fontconfig 治理 Linux 中的字体](https://catcat.cc/post/2021-03-07/)
## [Linux 下的字体调校指南](https://szclsya.me/zh-cn/posts/fonts/linux-config-guide/)
## [Font configuration/Examples](https://wiki.archlinux.org/title/Font_configuration/Examples)
## [Having multiple values in <test>](https://bbs.archlinuxcn.org/viewtopic.php?id=2736)
# fc-match -s | less
# fc-match sans-serif; fc-match serif; fc-match monospace
# fc-match mono-9:lang=zh-CN
if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cjk/fontconfig_${SYSTEM_LOCALE}.xml" ]]; then
    # sudo cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cjk/fontconfig_${SYSTEM_LOCALE}.xml" "/etc/fonts/local.conf"
    mkdir -p "$HOME/.config/fontconfig/"
    cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/cjk/fontconfig_${SYSTEM_LOCALE}.xml" "$HOME/.config/fontconfig/fonts.conf"
fi

# update font cache
colorEcho "${BLUE}Updating ${FUCHSIA}fontconfig cache${BLUE}..."
sudo fc-cache -fv >/dev/null 2>&1

# Fcitx5 input methods for Chinese Pinyin
# [Fcitx5](https://wiki.archlinux.org/title/Fcitx5)
# [Using Fcitx 5 on Wayland](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland)
# KDE Plasma: Start fcitx5 by go to "System settings"->"Virtual keyboard"->Select "Fcitx 5"
if checkPackageInstalled "fcitx"; then
    colorEcho "${BLUE}Installing ${FUCHSIA}fcitx5 input methods${BLUE}..."
    sudo pacman --noconfirm -Rs "$(pacman -Qsq fcitx)" 2>/dev/null
fi

## list of packages that belongs to the package group `fcitx5-im`
# pacman -Sp --print-format '%n' fcitx5-im
# yay --noconfirm --needed -S fcitx5-im

CJKInstallList=(
    # pacman -Sp --print-format '%n' "fcitx5-im"
    "fcitx5"
    "fcitx5-qt"
    "fcitx5-configtool"
    "fcitx5-gtk"
    "fcitx5-lua"
    "fcitx5-m17n"
    # [RIME - 中州韻輸入法引擎](https://rime.im/)
    "fcitx5-rime"
    # addons
    "fcitx5-chinese-addons"
    "fcitx5-pinyin-zhwiki"
    "fcitx5-pinyin-moegirl"
    # themes
    "fcitx5-material-color"
    "fcitx5-skin-materia-yanli"
    "fcitx5-skin-fluentdark-git"
    "fcitx5-skin-fluentlight-git"
    "fcitx5-nord"
    "fcitx5-breeze"
    # emoji & screen keyboard
    "aur/emoji-keyboard-bin" # [Emoji keyboard](https://github.com/OzymandiasTheGreat/emoji-keyboard)
    "aur/emote" # [Emote](https://github.com/tom-james-watson/Emote)
    "onboard" # [Onboard Onscreen Keyboard](https://launchpad.net/onboard)
)
InstallSystemPackages "" "${CJKInstallList[@]}"

if ! grep -q "XMODIFIERS" "/etc/environment" 2>/dev/null; then
    sudo tee -a "/etc/environment" >/dev/null <<-'EOF'

# Fcitx5
XMODIFIERS=@im=fcitx
QT_IM_MODULE=fcitx
GTK_IM_MODULE=fcitx
SDL_IM_MODULE=fcitx
EOF
fi

if ! grep -q "XMODIFIERS" "$HOME/.xprofile" 2>/dev/null; then
    tee -a "$HOME/.xprofile" >/dev/null <<-'EOF'

# Fcitx5
case "${XMODIFIERS}" in 
    *@im=fcitx*)
        export QT_IM_MODULE=fcitx
        export GTK_IM_MODULE=fcitx
        export SDL_IM_MODULE=fcitx
        ;;
    *@im=ibus*)
        export QT_IM_MODULE=ibus
        export GTK_IM_MODULE=ibus
        export SDL_IM_MODULE=ibus
        export IBUS_USE_PORTAL=1
        ;;
esac
EOF
fi

# Gtk2
if ! grep -q "^gtk-im-module=" "$HOME/.gtkrc-2.0" 2>/dev/null; then
    echo 'gtk-im-module="fcitx"' >> "$HOME/.gtkrc-2.0"
fi

# Gtk 3
if ! grep -q "^gtk-im-module=" "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null; then
    echo 'gtk-im-module=fcitx' >> "$HOME/.config/gtk-3.0/settings.ini"
fi

# Gtk 4
if ! grep -q "^gtk-im-module=" "$HOME/.config/gtk-4.0/settings.ini" 2>/dev/null; then
    echo 'gtk-im-module=fcitx' >> "$HOME/.config/gtk-4.0/settings.ini"
fi

if [[ "${OS_INFO_DESKTOP}" == "GNOME" ]]; then
    gsettings set org.gnome.settings-daemon.plugins.xsettings overrides "{'Gtk/IMModule':<'fcitx'>}"
fi

# Fcitx5 configuration
mkdir -p "$HOME/.config/fcitx5/conf"
if [[ ! -f "$HOME/.config/fcitx5/conf/classicui.conf" ]]; then
    if [[ -f "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/fcitx/classicui.conf" ]]; then
        cp "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/conf/ssh/classicui.conf" "$HOME/.config/fcitx5/conf/classicui.conf"
    fi
EOF
fi

## How to Insert Emojis & Special Characters
## [Unicode Character Code Charts](http://unicode.org/charts/)
## [Linux keyboard shortcuts for text symbols](https://fsymbols.com/keyboard/linux/)
## Linux keyboard: Unicode hex codes composition
# Hold down `Ctrl+Shift+U` keys (at the same time).
# Release the keys.
# Enter Unicode symbol's hex code.
# Enter hexadecimal (base 16 - 0123456789abcdef) code of symbol you want to type.
# For example try 266A to get ♪. Or 1F44F for 👏
# Press [Space] key

## KDE: [krunner-symbols](https://github.com/domschrei/krunner-symbols)
##      [KCharSelect](https://utils.kde.org/projects/kcharselect/)
if [[ "${OS_INFO_DESKTOP}" == "KDE" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}KCharSelect${BLUE}..."
    sudo pacman --noconfirm --needed -S kcharselect

    colorEcho "${BLUE}Installing ${FUCHSIA}krunner-symbols${BLUE}..."
    sudo pacman --noconfirm --needed -S ki18n krunner qt5-base cmake extra-cmake-modules

    mkdir -p "$HOME/Applications"
    Git_Clone_Update_Branch "domschrei/krunner-symbols" "$HOME/Applications/krunner-symbols"
    [[ -d "$HOME/Applications/krunner-symbols" ]] && cd "$HOME/Applications/krunner-symbols" && bash build_and_install.sh
fi

## GNOME: Insert Special Characters via `GNOME Characters` App
# GNOME Characters
if [[ "${OS_INFO_DESKTOP}" == "GNOME" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}GNOME Characters${BLUE}..."
    sudo pacman --noconfirm --needed -S gnome-characters

    if [[ -x "$(command -v snap)" && ! -x "$(command -v gnome-characters)" ]]; then
        sudo snap install gnome-characters
    fi
fi

## [Emoji keyboard](https://github.com/OzymandiasTheGreat/emoji-keyboard)
# INSTALLER_GITHUB_REPO="OzymandiasTheGreat/emoji-keyboard"
# INSTALLER_DOWNLOAD_FILE="$HOME/Applications/emoji-keyboard.AppImage"
# INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
# App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
# INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${INSTALLER_GITHUB_REPO}/releases/download/${INSTALLER_VER_REMOTE}/emoji-keyboard-${INSTALLER_VER_REMOTE}.AppImage"
# colorEcho "${BLUE}Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
# colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
# curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"

# [Emote](https://github.com/tom-james-watson/Emote): Modern popup emoji picker
# Launch the emoji picker with the configurable keyboard shortcut `Ctrl+Alt+E` 
# and select one or more emojis to paste them into the currently focussed app.
if [[ -x "$(command -v flatpak)" && ! -x "$(command -v emote)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}emote${BLUE}..."
    flatpak install -y "com.tomjwatson.Emote"
fi

# add to autostart
if [[ -x "$(command -v emote)" ]]; then
    tee "$HOME/.config/autostart/emote.desktop" >/dev/null <<-'EOF'
[Desktop Entry]
Encoding=UTF-8
Type=Application
Name=emote
Icon=emote-love
Comment=Modern popup emoji picker
Exec=/usr/bin/python3 "$(which emote)"
StartupNotify=false
Terminal=false
Hidden=false
EOF
fi

# SDDM: Virtual Keyboard on Login screen
if [[ -s "/etc/sddm.conf" ]]; then
    sudo sed -i 's|^InputMethod=.*|InputMethod=qtvirtualkeyboard|' "/etc/sddm.conf"
fi

# 以 [雾凇拼音](https://github.com/iDvel/rime-ice) 为基础，合并粵語拼音、四叶草等输入法方案
mkdir -p "$HOME/.local/share/fcitx5/rime/"
if [[ ! -f "$HOME/.local/share/fcitx5/rime/default.custom.yaml" ]]; then
    # source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/cjk_rime_symbols.sh"
    source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/cjk_fcitx_themes.sh"
    source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/cjk_rime_schema.sh"
fi

## Debug fcitx5
# fcitx5 --verbose="*=5" > fictx5_debug_log.txt 2>&1
# fcitx5-diagnose

colorEcho "${BLUE}Fcitx5 安装完成！"
colorEcho "${ORANGE}KDE Plasma 桌面："
colorEcho "  ${BLUE}设置虚拟键盘：${FUCHSIA}系统设置→键盘→虚拟键盘→Fcitx 5→应用"
colorEcho "  ${BLUE}添加输入法：${FUCHSIA}系统设置→输入法→+添加输入法...→中州韻→添加"
colorEcho "  ${BLUE}设置主题：${FUCHSIA}系统设置→输入法→配置附加组件...→经典用户界面→设置→主题"

cd "${CURRENT_DIR}" || exit
