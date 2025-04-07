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

[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# Local WAN GEO location
colorEcho "${BLUE}Checking ${FUCHSIA}GEO location${BLUE} by WAN IP..."
[[ -z "${NETWORK_WAN_NET_IP_GEO}" ]] && get_network_wan_geo
[[ "${NETWORK_WAN_NET_IP_GEO}" =~ 'China' || "${NETWORK_WAN_NET_IP_GEO}" =~ 'CN' ]] && IP_GEO_IN_CHINA="yes"
colorEcho "GEO location: ${FUCHSIA}${NETWORK_WAN_NET_IP_GEO}${BLUE}"

# [AUR package fails to verify PGP/GPG key: “unknown public key”, “One or more PGP signatures could not be verified!”](https://forum.manjaro.org/t/aur-package-fails-to-verify-pgp-gpg-key-unknown-public-key-one-or-more-pgp-signatures-could-not-be-verified/6663)
# gpg --recv-key $KEYID

# pacman
# Generate custom mirrorlist
# if [[ "${IP_GEO_IN_CHINA}" == "yes" ]]; then
#     colorEcho "${BLUE}Generating ${FUCHSIA}mirror lists${BLUE}..."
#     sudo pacman-mirrors -i -c China -m rank
# fi

# try to set up the fastest mirror
# https://wiki.manjaro.org/index.php/Pacman-mirrors
if [[ ! -f "/etc/pacman-mirrors.conf" ]]; then
    colorEcho "${BLUE}Setting ${FUCHSIA}pacman mirrors${BLUE}..."
    # sudo pacman-mirrors -i -c China,Taiwan -m rank
    # sudo pacman-mirrors -i --continent --timeout 2 -m rank
    sudo pacman-mirrors -i --geoip --timeout 2 -m rank
fi

# Show colorful output on the terminal
sudo sed -i 's|^#Color|Color|' /etc/pacman.conf

# Enable AUR, Snap, Flatpak in pamac
sudo sed -i -e 's|^#EnableAUR|EnableAUR|' \
    -e 's|^#EnableSnap|EnableSnap|' \
    -e 's|^#EnableFlatpak|EnableFlatpak|' /etc/pamac.conf

# sudo sed -i -e 's|^#CheckAURUpdates|CheckAURUpdates|' \
#     -e 's|^#CheckAURVCSUpdates|CheckAURVCSUpdates|' \
#     -e 's|^#CheckFlatpakUpdates|CheckFlatpakUpdates|' /etc/pamac.conf

## [Chaotic-AUR: Automated building repo for AUR packages](https://aur.chaotic.cx/)
# if ! grep -q "chaotic-aur" /etc/pacman.conf 2>/dev/null; then
#     colorEcho "${BLUE}Installing ${FUCHSIA}Chaotic-AUR${BLUE}..."
#     sudo pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
#     sudo pacman-key --lsign-key FBA220DFC880C036
#     sudo pacman --noconfirm -U \
#         'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
#         'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
#
#     echo -e "\n[chaotic-aur]" | sudo tee -a /etc/pacman.conf >/dev/null
#     echo "Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null
# fi

# [Arch Linux Chinese Community Repository](https://github.com/archlinuxcn/mirrorlist-repo)
if [[ "${IP_GEO_IN_CHINA}" == "yes" ]]; then
    if ! grep -q "archlinuxcn" /etc/pacman.conf 2>/dev/null; then
        colorEcho "${BLUE}Installing ${FUCHSIA}archlinuxcn${BLUE} repo..."
        echo -e "\n[archlinuxcn]" | sudo tee -a /etc/pacman.conf >/dev/null
        # echo "Server = https://repo.archlinuxcn.org/\$arch" | sudo tee -a /etc/pacman.conf >/dev/null
        export MIRROR_ARCHLINUX_CN=${MIRROR_ARCHLINUX_CN:-"https://mirrors.sjtug.sjtu.edu.cn"}
        echo "Server = ${MIRROR_ARCHLINUX_CN}/archlinux-cn/\$arch" | sudo tee -a /etc/pacman.conf >/dev/null

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
        #     sudo pacman -Scc && sudo pacman --noconfirm -Syu

        sudo pacman --noconfirm -Syy && \
            sudo pacman --noconfirm --needed -S archlinuxcn-keyring && \
            sudo pacman --noconfirm --needed -S archlinuxcn-mirrorlist-git
    fi
fi

# Full update
colorEcho "${BLUE}Updating ${FUCHSIA}full system${BLUE}..."
sudo pacman --noconfirm -Syu

# Language packs
if [[ "${IP_GEO_IN_CHINA}" == "yes" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}language packs${BLUE}..."
    sudo pacman --noconfirm --needed -S firefox-i18n-zh-cn thunderbird-i18n-zh-cn man-pages-zh_cn

    [[ -x "$(command -v gimp)" ]] && sudo pacman --noconfirm --needed -S gimp-help-zh_cn
fi

# pre-requisite packages
colorEcho "${BLUE}Installing ${FUCHSIA}pre-requisite packages${BLUE}..."
sudo pacman --noconfirm --needed -S bind git axel curl wget unzip seahorse yay fx croc magic-wormhole

# Build deps
colorEcho "${BLUE}Installing ${FUCHSIA}Build deps${BLUE}..."
sudo pacman --noconfirm --needed -S base-devel cmake patch pkg-config automake

# [Flatpak](https://flatpak.org/)
colorEcho "${BLUE}Installing ${FUCHSIA}Flatpak${BLUE}..."
sudo pacman --noconfirm --needed -S flatpak libpamac-flatpak-plugin
if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    [[ -z "${MIRROR_FLATPAK_URL}" ]] && MIRROR_FLATPAK_URL="https://mirror.sjtu.edu.cn/flathub"
    sudo flatpak remote-modify flathub --url="${MIRROR_FLATPAK_URL}"

    # sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    # sudo flatpak remote-add --if-not-exists flathub https://mirror.sjtu.edu.cn/flathub/flathub.flatpakrepo

    # flatpak remote-add --user --if-not-exists flathub https://mirror.sjtu.edu.cn/flathub/flathub.flatpakrepo
    # flatpak remote-modify --user flathub --url=https://mirror.sjtu.edu.cn/flathub

    flatpak remotes -d
fi

## [Discover](https://userbase.kde.org/Discover)
# colorEcho "${BLUE}Installing ${FUCHSIA}Discover${BLUE}..."
# sudo pacman --noconfirm --needed -S discover packagekit-qt5

# yay
# https://github.com/Jguer/yay
# yay <Search Term>               Present package-installation selection menu.
# yay -Ps                         Print system statistics.
# yay -Yc                         Clean unneeded dependencies.
# yay -G <AUR Package>            Download PKGBUILD from ABS or AUR.
# yay -Y --gendb                  Generate development package database used for devel update.
# yay -Syu --devel --timeupdate   Perform system upgrade, but also check for development package updates and 
#                                     use PKGBUILD modification time (not version number) to determine update.


# Accelerate the speed of AUR PKGBUILD with github.com
if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    sudo tee "/etc/makepkg_axel.sh" >/dev/null <<-'EOF'
#!/usr/bin/env bash

URL_DOMAIN=$(cut -f3 -d'/' <<< "$2")
URL_OTHERS=$(cut -f4- -d'/' <<< "$2")

AXEL_NO_PROXY="no"

case "${URL_DOMAIN}" in
    "github.com")
        url="${GITHUB_DOWNLOAD_URL:-https://github.com}/${URL_OTHERS}"
        [[ "${GITHUB_DOWNLOAD_URL:-https://github.com}" != "https://github.com" ]] && AXEL_NO_PROXY="yes"
        ;;
    "raw.githubusercontent.com")
        url="${GITHUB_RAW_URL:-https://raw.githubusercontent.com}/${URL_OTHERS}"
        [[ "${GITHUB_RAW_URL:-https://raw.githubusercontent.com}" != "https://raw.githubusercontent.com" ]] && AXEL_NO_PROXY="yes"
        ;;
    *)
        url=$2
        ;;
esac

## fix error: No state file, cannot resume!
# yay --noconfirm -Sc
# [[ -s "$1" ]] && rm "$1"

# /usr/bin/axel -N -n5 -a -o $1 $url || /usr/bin/axel -N -n5 -a -o $1 $2

if [[ "${AXEL_NO_PROXY}" == "yes" ]]; then
    /usr/bin/axel -N -n5 -a -o $1 $url || /usr/bin/curl -qgb "" -fLC - --retry 3 --retry-delay 3 -o $1 $2
else
    /usr/bin/axel -n5 -a -o $1 $url || /usr/bin/curl -qgb "" -fLC - --retry 3 --retry-delay 3 -o $1 $2
fi
EOF

    sudo chmod +x "/etc/makepkg_axel.sh"

    sudo cp -f "/etc/makepkg.conf" "/etc/makepkg.conf.bak"

    # sudo sed -i "s|'ftp::.*|'ftp::/usr/bin/axel -n 5 -a -o %o %u'|" "/etc/makepkg.conf"
    # sudo sed -i "s|'http::.*|'http::/usr/bin/axel -n 5 -a -o %o %u'|" "/etc/makepkg.conf"
    # sudo sed -i "s|'https::.*|'https::/usr/bin/axel -n 5 -a -o %o %u'|" "/etc/makepkg.conf"
    sudo sed -i "s|'https::.*|'https::/etc/makepkg_axel.sh %o %u'|" "/etc/makepkg.conf"
fi

# [Appimages](https://appimage.org/)
# [AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher)
colorEcho "${BLUE}Installing ${FUCHSIA}AppImageLauncher${BLUE}..."
yay --needed -S aur/appimagelauncher

if [[ ! -s "$HOME/.config/appimagelauncher.cfg" ]]; then
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/Applications"
    tee "$HOME/.config/appimagelauncher.cfg" >/dev/null <<-'EOF'
[AppImageLauncher]
destination = ~/Applications
enable_daemon = true
EOF
fi

# Change from exfat-utils to exfatprogs for exfat
colorEcho "${BLUE}Installing ${FUCHSIA}exfatprogs${BLUE}..."
yay --needed -S exfatprogs


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


# Running in virtual environment
[[ -z "${OS_INFO_VIRTUALIZED}" ]] && get_os_virtualized

# sshd
if [[ "${OS_INFO_VIRTUALIZED}" != "none" ]]; then
    colorEcho "${BLUE}Enabling ${FUCHSIA}sshd${BLUE}..."
    systemctl is-enabled sshd >/dev/null 2>&1 || \
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
