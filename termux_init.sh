#!/usr/bin/env bash

## termux: required storage access permission

## install git & openssh
# pkg up -y && pkg i -y git openssh

## init termux
# source <(curl -fsSL https://git.io/JPSue) && ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/termux_init.sh

## start openssh service
# sshd
## ssh port: 8022
# netstat -an | grep 8022

## local computer:
## gen ssh key
# ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "username@mail.com"
## run a simple http server using python3
# cd ~./ssh; python -m http.server 8080

## termux:
# curl -fsSL -o ~/.ssh/id_ed25519.pub "http://<local computer ip>:8080/id_ed25519.pub"
# cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

## local computer:
# cat >> ~/.ssh/config <<-EOF
# Host <phone>
#   Hostname <phone ip>
#   Port 8022
#   IdentityFile ~/.ssh/id_ed25519
#   User root
# EOF
# scp -Cp .ssh/* <phone>:~/.ssh/

## connect to phone using ssh:
# ssh <phone>
# rm -f .ssh/known_hosts && chmod 600 ~/.ssh/*

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

[[ -z "${READ_ARRAY_OPTS[*]}" ]] && Get_Read_Array_Options
[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# https://termux.com/
if [[ -z "$PREFIX" ]]; then
    colorEcho "${RED}This script only for Termux!"
    exit 0
fi

# extra keys rows
colorEcho "${BLUE}Setting ${FUCHSIA}termux.properties${BLUE}..."
mkdir -p "$HOME/.termux"
tee "$HOME/.termux/termux.properties" >/dev/null <<-'EOF'
extra-keys = [ \
        ['ESC','/','BACKSLASH','|','HOME','UP','END','PGUP','DEL'], \
        ['CTRL','ALT','TAB','ENTER','LEFT','DOWN','RIGHT','PGDN','BKSP'] \
    ]
EOF

# file editor
if [[ ! -s "$HOME/bin/termux-file-editor" ]]; then
    mkdir -p "$HOME/bin"
    tee "$HOME/bin/termux-file-editor" >/dev/null <<-'EOF'
#!/data/data/com.termux/files/usr/bin/sh

# if [ "${1##*.}" = "apk" ]; then
#     cd ~/apks
#     apktool decode "$1"
# elif [ "${1##*.}" = "pdf" ]; then
#     papis add "$1"
# fi

nano "$1"
EOF
fi

## apt mirror
# apt edit-sources
termux-change-repo

# colorEcho "${BLUE}Setting ${FUCHSIA}apt mirror${BLUE}..."
# sed -i 's/^deb /# deb /g' "$PREFIX/etc/apt/sources.list"
# echo "deb https://mirrors.tuna.tsinghua.edu.cn/termux stable main" >> "$PREFIX/etc/apt/sources.list"

# install packages
colorEcho "${BLUE}Installing ${FUCHSIA}packages${BLUE}..."
pkg upgrade -y && \
    pkg install -y binutils curl wget git nano openssh unzip unrar htop nmap rsync \
        bat eza fd fzf lsd lsof nnn screenfetch starship tree zoxide

# intallPrebuiltBinary 'naiveproxy#klzgrad/naiveproxy#tar.xz#naive*'
# intallPrebuiltBinary 'mihomo#MetaCubeX/mihomo#gz#mihomo*'

# Termux Sudo Without Root
# https://github.com/virtual-designer/termux-sudo-without-root
if [[ ! -x "$(command -v sudo)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}sudo${BLUE}..."
    Git_Clone_Update_Branch "virtual-designer/termux-sudo-without-root" "$HOME/sudo"
    if [[ -s "$HOME/sudo/sudo.deb" ]]; then
        apt install -y "$HOME/sudo/sudo.deb" && \
            chmod +w "$PREFIX/etc/sudoers" && \
            echo "$(whoami)|All|admin" >> "$PREFIX/etc/sudoers" && \
            chmod -w "$PREFIX/etc/sudoers"
    fi
fi

# pacapt
if [[ -x "$(command -v sudo)" && ! -x "$(command -v pacapt)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/pacapt_installer.sh" ]] && \
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/installer/pacapt_installer.sh"
fi

## reload termux settings
# termux-reload-settings

# https://wiki.termux.com/wiki/Termux:API
colorEcho "${BLUE}Installing ${FUCHSIA}termux-api${BLUE}..."
pkg i -y termux-api

# nanorc
if [[ ! -d "$HOME/.local/share/nanorc" ]]; then
    colorEcho "${BLUE}Setting nanorc..."
    Git_Clone_Update_Branch "scopatz/nanorc" "$HOME/.local/share/nanorc"
    tee "$HOME/.nanorc" >/dev/null <<-EOF
set titlecolor brightwhite,red
set statuscolor brightwhite,red
set selectedcolor brightwhite,cyan
set numbercolor magenta
set keycolor brightmagenta
set functioncolor magenta

include "$HOME/.local/share/nanorc/*.nanorc"
EOF
fi

# Remove Welcome screen Text
# cat $PREFIX/etc/motd
# touch ~/.hushlogin
mv "$PREFIX/etc/motd" "$PREFIX/etc/motd.bak" && echo -e "\nWelcome to Termux!" > "$PREFIX/etc/motd"

# zsh & oh-my-zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}zsh & oh-my-zsh${BLUE}..."
    sh -c "$(curl -fsSL https://github.com/Cabbagec/termux-ohmyzsh/raw/master/install.sh)"
fi

if [[ -s "$HOME/.zshrc" ]]; then
    colorEcho "${BLUE}Setting zsh..."
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # ys theme
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"ys\"/" "$HOME/.zshrc"

    # change the command execution time stamp shown in the history command output
    sed -i 's/[#]*[ ]*HIST_STAMPS.*/HIST_STAMPS="yyyy-mm-dd"/' "$HOME/.zshrc"

    # disable auto update
    sed -i "s/[#]*[ ]*DISABLE_AUTO_UPDATE.*/DISABLE_AUTO_UPDATE=\"true\"/" "$HOME/.zshrc"

    # zsh plugins
    colorEcho "${BLUE}Oh-my-zsh custom plugins..."
    sed -i '/zsh-syntax-highlighting.zsh/d' "$HOME/.zshrc"

    PluginList=(
        "zsh-users/zsh-history-substring-search"
        "zsh-users/zsh-autosuggestions"
        "zdharma-continuum/fast-syntax-highlighting"
        "Aloxaf/fzf-tab"
        "lincheney/fzf-tab-completion"
        "wfxr/forgit"
    )

    for Target in "${PluginList[@]}"; do
        TargetName=$(echo "${Target}" | awk -F"/" '{print $NF}')
        Git_Clone_Update_Branch "${Target}" "${ZSH_CUSTOM}/plugins/${TargetName}"
    done

    # Enable plugins
    colorEcho "${BLUE}enable zsh plugins..."
    Plugins="git cp rsync"

    [[ "$(command -v git-flow)" ]] && Plugins="${Plugins} git-flow-avh"
    [[ -x "$(command -v tmux)" ]] && Plugins="${Plugins} tmux"
    [[ -x "$(command -v fzf)" || -d "$HOME/.fzf" ]] && Plugins="${Plugins} fzf fzf-tab"

    Plugins="${Plugins} zoxide zsh-interactive-cd zsh-autosuggestions fast-syntax-highlighting history-substring-search"

    PluginList=()
    IFS=" " read -r "${READ_ARRAY_OPTS[@]}" PluginList <<< "${Plugins}"

    Plugins=""
    for TargetPlugin in "${PluginList[@]}"; do
        if [[ -n "$TargetPlugin" ]]; then
            if [[ -z "$Plugins" ]]; then
                Plugins="  ${TargetPlugin}"
            else
                Plugins="${Plugins}\n  ${TargetPlugin}"
            fi
        fi
    done

    # replace plugins in .zshrc
    sed -i "s/^plugins=(git)/plugins=(\n  git\n)/" "$HOME/.zshrc"

    LineBegin=$(cat -n "$HOME/.zshrc" | grep 'plugins=(' | awk '{print $1}' | tail -n1)
    LineShift=$(tail -n +"${LineBegin}" "$HOME/.zshrc" | cat -n | grep ')' | awk '{print $1}' | head -n1)
    LineEnd=$((LineBegin + LineShift - 1))

    if [[ -n "$LineBegin" && -n "$LineEnd" ]]; then
        DeleteBegin=$((LineBegin + 1))
        DeleteEnd=$((LineEnd - 1))
        sed -i "${DeleteBegin},${DeleteEnd}d" "$HOME/.zshrc"
    fi

    [[ -n "$LineBegin" ]] && sed -i "${LineBegin}a\\${Plugins}" "$HOME/.zshrc"

    # custom configuration
    if ! grep -q "zsh_custom_conf.sh" "$HOME/.zshrc" 2>/dev/null; then
        colorEcho "${BLUE}Source custom configuration ${FUCHSIA}~/.dotfiles/zsh/zsh_custom_conf.sh${BLUE} in ${ORANGE}.zshrc${BLUE}..."
        echo -e "\n# Custom configuration\nsource ~/.dotfiles/zsh/zsh_custom_conf.sh" >> "$HOME/.zshrc"
    fi

    # sshd auto start
    if ! grep -q "sshd" "$HOME/.zshrc" 2>/dev/null; then
        colorEcho "${BLUE}Setting sshd start with zsh..."
        echo "sshd" >> "$HOME/.zshrc"
    fi
fi

# font: Fira Code Regular Nerd Font Complete Mono
colorEcho "${BLUE}Installing ${FUCHSIA}FiraCode-Mono${BLUE}..."
if [[ ! -s "$HOME/FiraCode-Mono/Fira Code Regular Nerd Font Complete Mono.ttf" ]]; then
    NerdFont_URL="https://github.com/epoweripione/fonts/releases/download/v0.1.0/FiraCode-Mono-6.2.0.zip"
    curl "${CURL_DOWNLOAD_OPTS[@]}" "${NerdFont_URL}" -o "$HOME/FiraCode-Mono.zip" && \
        mkdir -p "$HOME/FiraCode-Mono" && \
        unzip -q "$HOME/FiraCode-Mono.zip" -d "$HOME/FiraCode-Mono" && \
        rm -f "$HOME/FiraCode-Mono.zip"
fi

if [[ -s "$HOME/FiraCode-Mono/Fira Code Regular Nerd Font Complete Mono.ttf" ]]; then
    [[ -s "$HOME/.termux/font.ttf" && ! -s "$HOME/.termux/font.ttf.bak" ]] && \
        mv "$HOME/.termux/font.ttf" "$HOME/.termux/font.ttf.bak"

    cp -f "$HOME/FiraCode-Mono/Fira Code Regular Nerd Font Complete Mono.ttf" "$HOME/.termux/font.ttf"
fi

# nnn
if [[ -x "$(command -v nnn)" ]]; then
    [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/nnn" ]] && \
        find "${XDG_CONFIG_HOME:-$HOME/.config}/nnn" -type f -name "plugins-*.tar.gz" -delete

    [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins" ]] && \
        rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins"

    curl -fsL "https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs" | sh
fi

# frp
if [[ ! -d "$HOME/frp" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}frp${BLUE}..."
    INSTALLER_CHECK_URL="https://api.github.com/repos/fatedier/frp/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"

    if [[ -n "${INSTALLER_VER_REMOTE}" ]]; then
        INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/fatedier/frp/releases/download/v${INSTALLER_VER_REMOTE}/frp_${INSTALLER_VER_REMOTE}_linux_arm64.tar.gz"
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o frp.tar.gz "${INSTALLER_DOWNLOAD_URL}" && \
            tar -xzf frp.tar.gz -C "$HOME" && \
            rm frp.tar.gz && \
            mkdir -p "$HOME/frp" && \
            cp -rf "$HOME"/frp_*/* "$HOME/frp" && \
            rm -rf "$HOME"/frp_*/
    fi
fi
# cd "$HOME/frp/" && nohup ./frpc -c ./frpc.ini >/dev/null 2>&1 & disown

## webui-aria2
# colorEcho "${BLUE}Installing ${FUCHSIA}webui-aria2${BLUE}..."
# pkg i -y aria2 nodejs
# Git_Clone_Update_Branch "ziahamza/webui-aria2" "$HOME/webui-aria2"
# [[ -d "$HOME/webui-aria2" ]] && cd "$HOME/webui-aria2" && node node-server.js

cd "${CURRENT_DIR}" || exit