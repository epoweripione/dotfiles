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

# Fonts
colorEcho "${BLUE}Installing ${FUCHSIA}fonts${BLUE}..."
yay --noconfirm --needed -S powerline-fonts ttf-fira-code ttf-sarasa-gothic \
    ttf-hannom noto-fonts noto-fonts-extra noto-fonts-emoji noto-fonts-cjk \
    ttf-twemoji unicode-emoji

# yay --noconfirm --needed -S ttf-dejavu ttf-droid ttf-hack ttf-font-awesome otf-font-awesome \
#     ttf-lato ttf-liberation ttf-linux-libertine ttf-opensans ttf-roboto ttf-ubuntu-font-family

# yay --noconfirm --needed -S adobe-source-code-pro-fonts adobe-source-sans-fonts adobe-source-serif-fonts \
#     adobe-source-han-sans-cn-fonts adobe-source-han-sans-hk-fonts adobe-source-han-sans-tw-fonts \
#     adobe-source-han-serif-cn-fonts wqy-zenhei wqy-microhei

# FiraCode Nerd Font Complete Mono
colorEcho "${BLUE}Installing ${FUCHSIA}FiraCode Nerd Font Complete Mono${BLUE}..."
NerdFont_URL="https://github.com/epoweripione/fonts/releases/download/v0.1.0/FiraCode-Mono-6.2.0.zip"
mkdir -p "${WORKDIR}/FiraCode-Mono" && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/FiraCode-Mono.zip" "${NerdFont_URL}" && \
    unzip -q "${WORKDIR}/FiraCode-Mono.zip" -d "${WORKDIR}/FiraCode-Mono" && \
    sudo mv -f "${WORKDIR}/FiraCode-Mono/" "/usr/share/fonts/" && \
    sudo chmod -R 744 "/usr/share/fonts/FiraCode-Mono"
# fc-list | grep "FiraCode" | column -t -s ":"

# CJK fontconfig & colour emoji
# https://wiki.archlinux.org/title/Localization_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)/Simplified_Chinese_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
colorEcho "${BLUE}Setting ${FUCHSIA}CJK fontconfig & colour emoji${BLUE}..."
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
colorEcho "${BLUE}Installing ${FUCHSIA}fcitx5 input methods${BLUE}..."
sudo pacman --noconfirm --needed -Rs "$(pacman -Qsq fcitx)"
sudo pacman --noconfirm --needed -S fcitx5-im && \
    sudo pacman --noconfirm --needed -S fcitx5-material-color fcitx5-chinese-addons && \
    sudo pacman --noconfirm --needed -S fcitx5-pinyin-zhwiki fcitx5-pinyin-moegirl
# sudo pacman --noconfirm --needed -S fcitx5-anthy fcitx5-rime rime-cloverpinyin

if ! grep -q "^GTK_IM_MODULE" "$HOME/.pam_environment" 2>/dev/null; then
    tee -a "$HOME/.pam_environment" >/dev/null <<-'EOF'
# fcitx5
INPUT_METHOD DEFAULT=fcitx5
GTK_IM_MODULE DEFAULT=fcitx5
QT_IM_MODULE  DEFAULT=fcitx5
XMODIFIERS    DEFAULT=\@im=fcitx5
SDL_IM_MODULE DEFAULT=fcitx5
EOF
fi

if ! grep -q "^export GTK_IM_MODULE" "$HOME/.xprofile" 2>/dev/null; then
    tee -a "$HOME/.xprofile" >/dev/null <<-'EOF'
# fcitx5
export INPUT_METHOD DEFAULT=fcitx5
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS="@im=fcitx5"
export SDL_IM_MODULE=fcitx5

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


cd "${CURRENT_DIR}" || exit
