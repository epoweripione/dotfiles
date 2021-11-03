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

# Local WAN IP
if [[ -z "$WAN_NET_IP" ]]; then
    get_network_wan_ipv4
    get_network_wan_geo
fi

if [[ "${WAN_NET_IP_GEO}" =~ 'China' || "${WAN_NET_IP_GEO}" =~ 'CN' ]]; then
    IP_GEO_IN_CHINA="yes"
fi

[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

# pacman
# Generate custom mirrorlist
if [[ "$IP_GEO_IN_CHINA" == "yes" ]]; then
    sudo pacman-mirrors -i -c China -m rank
fi

# Show colorful output on the terminal
sudo sed -i 's|^#Color|Color|' /etc/pacman.conf


## Arch Linux Chinese Community Repository
## https://github.com/archlinuxcn/mirrorlist-repo
# colorEchoN "${ORANGE}Add Arch Linux Chinese Community Repository?[y/${CYAN}N${ORANGE}]: "
# read -r CHOICE
## CHOICE=$(echo $CHOICE | sed 's/.*/\U&/')
# if [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]]
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


# Do full system update
sudo pacman --noconfirm -Syu


# Virtualbox
# https://forum.manjaro.org/t/howto-virtualbox-installation-usb-shared-folders/55905
# MANJARO GUEST installation
# Before installation ensure you are using VBoxSVGA graphics
# run `mhwd` to check that it’s using video-virtualbox
# mhwd -li && mhwd-kernel -li
colorEchoN "${ORANGE}Install virtualbox-guest-utils?[y/${CYAN}N${ORANGE}]: "
read -r CHOICE
if [[ "$CHOICE" == 'y' || "$CHOICE" == 'Y' ]]; then
    sudo pacman -S virtualbox-guest-utils \
        "linux$(uname -r|cut -d'.' -f1-2|sed 's/\.//')-virtualbox-guest-modules"
    # MANJARO GUEST Configuration
    sudo gpasswd -a "$USER" vboxsf
    sudo systemctl enable --now vboxservice
    # LINUX Shared folders
    # Host Configuration: On the host locate the Settings section in VirtualBox GUI,
    # Make the folders Permanent and Automount
    tee -a "$HOME/vboxmount.sh" >/dev/null <<-'EOF'
#!/bin/sh
#-----------------------------------------------------------------------------
# Discover VirtualBox shared folders and mount them if it makes sense
# Folders with the same name must exist in the $USER home folder
#-----------------------------------------------------------------------------
if ! type VBoxControl > /dev/null; then
    echo "VirtualBox Guest Additions NOT found" > /dev/stderr
    exit 1
fi

MY_UID="$(id -u)"
MY_GID="$(id -g)"

( set -x; sudo VBoxControl sharedfolder list; )  |  \
    grep      '^ *[0-9][0-9]* *- *'              |  \
    sed  -e 's/^ *[0-9][0-9]* *- *//'            |  \
    while read SHARED_FOLDER; do
        MOUNT_POINT="$HOME/$SHARED_FOLDER"
        if [ -d "$MOUNT_POINT" ]; then
            MOUNTED="$(mount | grep "$MOUNT_POINT")"
            if [ "$MOUNTED" ]; then
                echo "Already mounted :  $MOUNTED"
            else
            (
                set -x
                sudo mount -t vboxsf -o \
                    "nosuid,uid=$MY_UID,gid=$MY_GID" \
                    "$SHARED_FOLDER" "$MOUNT_POINT"
            )
            fi
        fi
    done
EOF

    chmod +x "$HOME/vboxmount.sh"
    Install_systemd_Service "vboxmount" "$HOME/vboxmount.sh"
fi


## Hyper-V
## https://medium.com/@iceboundrock/%E5%9C%A8hyper-v%E9%87%8C%E5%AE%89%E8%A3%85manjaro-kde-1bdf810dbc10
# sudo pacman --noconfirm -S lightdm lightdm-slick-greeter lightdm-settings
# sudo systemctl enable lightdm.service --force
## reboot
# sudo pacman -R sddm-kcm sddm


# RDP Server
# http://www.xrdp.org/
# https://wiki.archlinux.org/index.php/xrdp
sudo pacman --noconfirm -S xrdp
# yay --noconfirm -S xorgxrdp xrdp
echo 'allowed_users=anybody' | sudo tee -a /etc/X11/Xwrapper.config
sudo systemctl enable xrdp xrdp-sesman && \
    sudo systemctl start xrdp xrdp-sesman

## xrdp login failed with xorg
## https://github.com/neutrinolabs/xrdp/issues/1554

# RDP Client
sudo pacman --noconfirm -S freerdp remmina
