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

# Local WAN GEO location
[[ -z "${NETWORK_WAN_NET_IP_GEO}" ]] && get_network_wan_geo
[[ "${NETWORK_WAN_NET_IP_GEO}" =~ 'China' || "${NETWORK_WAN_NET_IP_GEO}" =~ 'CN' ]] && IP_GEO_IN_CHINA="yes"

# pacman
# Generate custom mirrorlist
if [[ "${IP_GEO_IN_CHINA}" == "yes" ]]; then
    colorEcho "${BLUE}Generating ${FUCHSIA}mirror lists${BLUE}..."
    sudo pacman-mirrors -i -c China -m rank
fi

# Show colorful output on the terminal
sudo sed -i 's|^#Color|Color|' /etc/pacman.conf

# Arch Linux Chinese Community Repository
# https://github.com/archlinuxcn/mirrorlist-repo
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

    sudo pacman --noconfirm -Syy && \
        sudo pacman --noconfirm --needed -S archlinuxcn-keyring && \
        sudo pacman --noconfirm --needed -S archlinuxcn-mirrorlist-git
fi

# Full update
colorEcho "${BLUE}Updating ${FUCHSIA}full system${BLUE}..."
sudo pacman --noconfirm --needed -Syu

# Language packs
colorEcho "${BLUE}Installing ${FUCHSIA}language packs${BLUE}..."
sudo pacman --noconfirm --needed -S firefox-i18n-zh-cn thunderbird-i18n-zh-cn man-pages-zh_cn

[[ -x "$(command -v gimp)" ]] && sudo pacman --noconfirm --needed -S gimp-help-zh_cn

# Build deps
sudo pacman --noconfirm --needed -S patch pkg-config automake

# pre-requisite packages
colorEcho "${BLUE}Installing ${FUCHSIA}pre-requisite packages${BLUE}..."
sudo pacman --noconfirm --needed -S bind git axel curl wget unzip seahorse yay fx croc magic-wormhole

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
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    sudo tee "/etc/makepkg_axel.sh" >/dev/null <<-'EOF'
#!/usr/bin/env bash

URL_DOMAIN=$(cut -f3 -d'/' <<< "$2")
URL_OTHERS=$(cut -f4- -d'/' <<< "$2")
case "${URL_DOMAIN}" in
    "github.com")
        url="https://download.fastgit.org/${URL_OTHERS}"
        ;;
    *)
        url=$2
        ;;
esac

## fix error: No state file, cannot resume!
# yay --noconfirm -Sc
# [[ -s "$1" ]] && rm "$1"

/usr/bin/axel -n 5 -a -o $1 $url || /usr/bin/curl -qgb "" -fLC - --retry 3 --retry-delay 3 -o $1 $2
EOF

    sudo chmod +x "/etc/makepkg_axel.sh"

    sudo cp -f "/etc/makepkg.conf" "/etc/makepkg.conf.bak"

    # sudo sed -i "s|'ftp::.*|'ftp::/usr/bin/axel -n 5 -a -o %o %u'|" "/etc/makepkg.conf"
    # sudo sed -i "s|'http::.*|'http::/usr/bin/axel -n 5 -a -o %o %u'|" "/etc/makepkg.conf"
    # sudo sed -i "s|'https::.*|'https::/usr/bin/axel -n 5 -a -o %o %u'|" "/etc/makepkg.conf"
    sudo sed -i "s|'https::.*|'https::/etc/makepkg_axel.sh %o %u'|" "/etc/makepkg.conf"
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
