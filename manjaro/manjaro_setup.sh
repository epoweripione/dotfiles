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

[[ -z "${OS_INFO_DESKTOP}" ]] && get_os_desktop

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
        sed -i -e "s/${FOLDER_ENCODE^^}/${FOLDER_EN[$FOLDER_INDEX]}/g" "$HOME/.local/share/user-places.xbel"
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

# Install apps
# Maybe load app list from `$HOME/.dotfiles.env.local` in `zsh_custom_conf.sh`
if [[ -z "${AppManjaroInstallList[*]}" ]]; then
    AppManjaroInstallList=(
        ## RDP Server
        # "xrdp"
        ## RDP Client
        "freerdp"
        "remmina"
        "rustdesk-bin"
        ## Desktop
        # "dmenu"
        ## picom: a standalone compositor for Xorg, a fork of compton
        ## rofi: a window switcher, run dialog, ssh-launcher and dmenu replacement
        ## feh: Fast and light imlib2-based image viewer
        ## inkscape: Professional vector graphics editor
        ## mate-power-manager: Power management tool for the MATE desktop
        ## mpd: Flexible, powerful, server-side application for playing music
        ## ncmpcpp: Fully featured MPD client using ncurses
        ## polybar: A fast and easy-to-use status bar
        ## scrot: command-line screenshot utility for X
        ## xcompmgr: Composite Window-effects manager for X.org
        "picom"
        "rofi"
        "feh"
        "inkscape"
        "mate-power-manager"
        "mpd"
        "ncmpcpp"
        "polybar"
        "scrot"
        ## xmonad https://xmonad.org/
        # "xmonad"
        # "xmonad-contrib"
        # "xmonad-utils"
        # "slock"
        # "xmobar"
        ## i3 https://i3wm.org/
        ## https://www.zhihu.com/question/62251457
        ## https://github.com/levinit/i3wm-config
        ## https://zocoxx.com/archlinux-i3wm.html
        # "i3-gaps"
        # "i3-scripts"
        # "i3-scrot"
        # "i3blocks"
        # "i3lock"
        # "i3status"
        # "i3exit"
        # "arc-icon-theme"
        # "adwaita-icon-theme"
        # "lxappearance"
        # "manjaro-wallpapers-by-lunix-i3"
        ## Broswer
        "chromium"
        "google-chrome"
        # "google-chrome-beta"
        "google-chrome-dev"
        # "microsoft-edge-stable-bin"
        "profile-sync-daemon"
        ## Clipborad
        "copyq"
        ## Develop
        "hub"
        # "jdk-openjdk"
        # "jre-openjdk"
        "dbeaver"
        "dbeaver-plugin-apache-poi"
        "dbeaver-plugin-batik"
        "dbeaver-plugin-office"
        "dbeaver-plugin-svg-format"
        "wireshark-qt"
        "visual-studio-code-bin"
        # "aur/powershell-bin"
        "extra/geany"
        "extra/geany-plugins"
        "aur/geany-themes"
        # "extra/notepadqq"
        "archlinuxcn/notepad---git"
        "aur/cudatext-qt5-bin"
        ## Dictionary
        # "goldendict-git"
        ## Download & Upload
        "aria2"
        "you-get"
        "filezilla"
        "archlinuxcn/qbittorrent-enhanced-git"
        ## Docker
        "docker"
        "docker-compose"
        # "kitematic"
        "distrobox"
        ## [Podman](https://wiki.archlinux.org/title/Podman)
        # "extra/podman"
        # "extra/cni-plugins"
        # "extra/buildah"
        # "extra/podman-docker"
        # "extra/podman-compose"
        # "chaotic-aur/podman-desktop"
        ## File & dir compare
        "meld"
        ## Free disk space and maintain privacy
        "bleachbit"
        ## IM
        "telegram-desktop"
        "aur/linuxqq"
        # "aur/deepin-wine-qq"
        "aur/deepin-wine-tim"
        "aur/wechat-uos"
        # "aur/deepin-wine-wechat"
        # "archlinuxcn/wine-wechat-setup"
        # "archlinuxcn/wine-for-wechat"
        "aur/wemeet-bin"
        ## Markdown
        "vnote-git"
        #"typora"
        ## Note
        #"leanote"
        #"wiznote"
        #"cherrytree"
        ## Netdisk
        "baidunetdisk-bin"
        ## Password manager
        "enpass"
        "keepass"
        "bitwarden"
        ## PDF Reader
        "evince"
        #"foxitreader"
        ## Player
        "netease-cloud-music"
        #"qqmusic-bin"
        "smplayer"
        "smplayer-skins"
        "smplayer-themes"
        ## Proxy
        "aur/frps-bin"
        "aur/frpc-bin"
        ## Screenshot
        "deepin-screenshot"
        "flameshot"
        #"xfce4-screenshooter"
        ## Quick search
        "synapse"
        "utools"
        ## Linux Advanced Power Management
        "tlp"
        "tlp-rdw"
        "tlpui"
        ## System
        "filelight"
        "peek"
        "redshift"
        "ventoy-bin"
        "wsysmon-git"
        "archlinuxcn/mission-center"
        #"easystroke"
        ## WPS
        "wps-office-cn"
        "wps-office-mui-zh-cn"
        "wps-office-mime-cn"
        "wps-office-fonts"
        "ttf-wps-fonts"
        "wps-office-all-dicts-win-languages"
        ## [LibreOffice](https://wiki.archlinux.org/title/LibreOffice)
        # "extra/libreoffice-fresh"
        # "extra/libreoffice-fresh-zh-cn"
        # "extra/libreoffice-extension-writer2latex"
        # "extra/libreoffice-extension-texmaths"
        # "archlinuxcn/libreoffice-extension-languagetool"
        ## [TeX Live](https://wiki.archlinux.org/title/TeX_Live)
        "texlive"
        "texlive-langchinese"
        # XeLaTex Compiler: Options -> configure TeXstudio -> Default Compiler -> XeLaTex
        "texstudio"
        # "lyx"
        ## Beamer
        # "beamerpresenter"
        # "beamer-theme-metropolis"
        # "bed-latex"
    )
fi

colorEcho "${BLUE}Checking install status for ${FUCHSIA}${AppManjaroInstallList[*]}${BLUE}..."
AppsToInstall=()
for TargetApp in "${AppManjaroInstallList[@]}"; do
    if checkPackageNeedInstall "${TargetApp}"; then
        AppsToInstall+=("${TargetApp}")
    fi
done

if [[ -n "${AppsToInstall[*]}" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}${AppsToInstall[*]}${BLUE}..."
    yay --noconfirm --needed -S "${AppsToInstall[@]}"
fi

# Snap apps
if [[ -z "${AppSnapInstallList[*]}" ]]; then
    AppSnapInstallList=(
        "motrix"
    )
fi
for TargetApp in "${AppSnapInstallList[@]}"; do
    colorEcho "${BLUE}Installing ${FUCHSIA}${TargetApp}${BLUE}..."
    sudo snap install "${TargetApp}"
done

## RDP Server
## http://www.xrdp.org/
## https://wiki.archlinux.org/index.php/xrdp
# colorEcho "${BLUE}Installing ${FUCHSIA}xrdp${BLUE}..."
# echo 'allowed_users=anybody' | sudo tee -a /etc/X11/Xwrapper.config
# sudo systemctl enable xrdp xrdp-sesman && \
#     sudo systemctl start xrdp xrdp-sesman

## DWM
## https://wiki.archlinux.org/index.php/Dwm_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
## https://github.com/GoDzM4TT3O/dotfiles
# git clone --recurse-submodules https://github.com/GoDzM4TT3O/dotfiles && \
#     cd dotfiles && \
#     cp -r .{config,vim*,z*,x*,X*,alias*,p10k.zsh,local} $HOME && \
#     cp -r dwm $HOME

# [NotePad--](https://gitee.com/cxasm/notepad--)
if [[ -x "$(command -v NotePad--)" ]]; then
    if [[ -s "/usr/share/applications/io.gitee.cxasm.notepad--.desktop" ]]; then
        sudo sed -i -e 's/notepad--/NotePad--/g' \
            -e 's/Notepad--/NotePad--/g' \
            -e 's/Icon=NotePad--/Icon=notepad--/' \
            "/usr/share/applications/io.gitee.cxasm.notepad--.desktop"
    fi

    if [[ -s "$HOME/.local/share/applications/io.gitee.cxasm.notepad--.desktop" ]]; then
        sed -i -e 's/notepad--/NotePad--/g' \
            -e 's/Notepad--/NotePad--/g' \
            -e 's/Icon=NotePad--/Icon=notepad--/' \
            "$HOME/.local/share/applications/io.gitee.cxasm.notepad--.desktop"
    fi
fi

## Linux Advanced Power Management
if [[ -x "$(command -v tlp)" ]]; then
    sudo systemctl enable --now tlp.service
fi
# sudo tlp start
# sudo tlp-stat -s # System Info
# sudo tlp-stat -b # Battery Care

## [Virtualbox](https://wiki.archlinux.org/title/VirtualBox)
# yay --noconfirm --needed -S extra/virtualbox extra/virtualbox-guest-iso
# yay --noconfirm --needed -S aur/virtualbox-bin aur/virtualbox-bin-guest-iso aur/virtualbox-ext-oracle
# sudo usermod -aG vboxusers "$USER"

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

# [He3](https://he3.app/)
[[ -s "${MY_SHELL_SCRIPTS}/installer/he3_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/he3_installer.sh"

# [洛雪音乐助手桌面版](https://github.com/lyswhut/lx-music-desktop)
[[ -s "${MY_SHELL_SCRIPTS}/installer/lx-music-desktop_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/lx-music-desktop_installer.sh"

# Notepadqq
# [[ -s "${MY_SHELL_SCRIPTS}/installer/notepadqq_installer.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/notepadqq_installer.sh"

# Themes
# [[ -s "${MY_SHELL_SCRIPTS}/installer/desktop_themes.sh" ]] && source "${MY_SHELL_SCRIPTS}/installer/desktop_themes.sh"


## [Profile-sync-daemon](https://wiki.archlinux.org/title/Profile-sync-daemon)
## $HOME/.config/psd/psd.conf
# systemctl --user enable --now psd.service
# psd parse

# [Environment variables](https://wiki.archlinux.org/title/environment_variables)
# [Session Environment Variables](https://userbase.kde.org/Session_Environment_Variables)
if [[ -s "$HOME/.dotfiles/manjaro/desktop_environment_variables.sh" ]]; then
    ENV_VAR_FILE=""
    [[ "${OS_INFO_DESKTOP}" == "KDE" ]] && ENV_VAR_FILE="$HOME/.config/plasma-workspace/env/desktop_environment_variables.sh"

    if [[ -n "${ENV_VAR_FILE}" && ! -s "${ENV_VAR_FILE}" ]]; then
        cp "$HOME/.dotfiles/manjaro/desktop_environment_variables.sh" "${ENV_VAR_FILE}"
    fi
fi

## Others
# mute tone when logout
echo -e "\n# Disable BIOS sound\nxset -b" | sudo tee -a "/etc/xprofile" > /dev/null

# Disable PC speaker
# su -c 'modprobe -r pcspkr && echo "blacklist pcspkr" >> /etc/modprobe.d/50-blacklist.conf'
echo -e "\n# Disable PC speaker\nblacklist pcspkr" | sudo tee "/etc/modprobe.d/nobeep.conf"

## Disable swap
## sudo sysctl -a | grep "vm.swappiness"
# SWAP_DISK=$(swapon --noheadings | awk '{print $1}')
# if [[ -n "${SWAP_DISK}" ]]; then
#     sudo swapoff "${SWAP_DISK}"
#     sudo systemctl mask swap
#     sudo sed -i -e 's/.*swap.*/# &/g' /etc/fstab
#     echo 'vm.swappiness=0' | sudo tee /etc/sysctl.d/99-swappiness.conf >/dev/null
# fi

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
