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

# [KWin/Wayland](https://community.kde.org/KWin/Wayland)
# [Wayland](https://wiki.archlinux.org/title/Wayland)
# XDG_SESSION_TYPE=wayland
InstallList=(
    # "aur/binder_linux-dkms"
    "waydroid"
    "archlinuxcn/waydroid-helper"
    # "archlinuxcn/waydroid-image"
    "archlinuxcn/waydroid-image-gapps"
    "archlinuxcn/waydroidsu"
)
InstallSystemPackages "" "${InstallList[@]}"

## check if the kernel supports Android features
# zgrep -i -e android -e memfd -e ashmem /proc/config.gz

## [Plasma (Wayland) session stuck on a black screen](https://discuss.kde.org/t/solved-plasma-wayland-session-stuck-on-a-black-screen/6691)
# if ! grep -q "^KWIN_DRM_NO_AMS=" "/etc/environment"; then
#     echo "KWIN_DRM_NO_AMS=1" || sudo tee -a "/etc/environment" >/dev/null
# fi

## Switch to Wayland
## Log out, click user-name and use the bottom drop-down box to select `Plasma (Wayland)` desktop session
## And, finally type user password to log in
# echo $XDG_SESSION_TYPE

## Run app via Wayland protocol
## Start app executable file via `startplasma-wayland` at the beginning
## For example, to run `Dolphin` file manager via Wayland, use command in terminal (`konsole`):
# startplasma-wayland dolphin
## Edit the app shortcut file under `/usr/share/applications` (or copy to .local/share/applications), and add the variable to `Exec`.
## So you can start the app via Wayland protocol even from start menu.

# Wayland IME Support
if [[ "${XDG_SESSION_TYPE}" == "wayland" ]]; then
    # setWaylandIMEChrome
    setWaylandIMEVSCode
    setWaylandIMEWPSOffice
    setWaylandIMELibreOffice
fi

# [Waydroid](https://wiki.archlinux.org/title/Waydroid)
# [在 Archlinux KDE下使用 Waydroid](https://zhuanlan.zhihu.com/p/643889264)

## Initialize Waydroid
# sudo waydroid init

# Initialize Waydroid with GApps support
sudo waydroid init -s GAPPS

sudo systemctl enable --now waydroid-container.service
# sudo systemctl start waydroid-container.service

## Usage
waydroid session start

## Launch a GUI
# waydroid --details-to-stdout show-full-ui
waydroid show-full-ui

# waydroid shell # Launch a shell
# waydroid app install $path_to_apk Install an application
# waydroid app list # Get the application list
# waydroid app launch $package_name # Run an application


## Network
## Check if Waydroid has basic connectivity
# sudo waydroid shell ping 8.8.8.8

## DNS traffic needs to be allowed
## nftables
# sudo nft list ruleset
# sudo nft list tables
# sudo nft add table "inet" filter
# sudo nft add chain "inet" filter "input" \{ type filter hook input priority 0 \; policy accept \; \}
# sudo nft add chain "inet" filter "forward" \{ type filter hook forward priority 0 \; policy accept \; \}
# sudo nft list chain "inet" filter "input"
# sudo nft list chain "inet" filter "forward"
# sudo nft add rule "inet" filter "input" iifname "waydroid0" accept
# sudo nft add rule "inet" filter "forward" iifname "waydroid0" accept
# sudo nft add rule "inet" filter "forward" oifname "waydroid0" accept
# sudo nft list table "inet" filter
# sudo nft list table "inet" filter | sudo tee -a /etc/nftables.conf >/dev/null

## ufw
# ufw allow 67
# ufw allow 53
## Packet forwarding needs to be allowed:
# ufw default allow FORWARD

## firewalld
## DNS:
# firewall-cmd --zone=trusted --add-port=67/udp
# firewall-cmd --zone=trusted --add-port=53/udp
## Packet forwarding:
# firewall-cmd --zone=trusted --add-forward
## Add the waydroid interface to a trusted:
# firewall-cmd --zone=trusted --add-interface=waydroid0
## We assume that interface `waydroid0` created by waydroid should be in the firewalld zone trusted automatically.
## If not so, please adjust those commands above or move interface waydroid0 to trusted. You may also need
# firewall-cmd --runtime-to-permanent


## Set the Global Proxy
## Identify the Host Gateway IP
# ip addr show "waydroid0"
# host_ip=$(ip addr show "waydroid0" 2>/dev/null | grep "inet\|inet6" | awk '{print $2}' | cut -d'/' -f1)
## Set the Global Proxy
# sudo waydroid shell settings put global http_proxy "${host_ip:-"192.168.240.1"}":7890
# sudo waydroid shell settings put global https_proxy "${host_ip:-"192.168.240.1"}":7890
# sudo waydroid shell settings get global http_proxy
# sudo waydroid shell settings get global https_proxy
## Remove the proxy settings
# sudo waydroid shell settings delete global http_proxy
# sudo waydroid shell settings delete global https_proxy

## Alternative: ADB Reverse (for localhost proxies)
## Get the Waydroid IP
# waydroid status
# adb connect 192.168.240.112:5555
## List of devices attached
# adb devices
## Forward the port
# adb reverse tcp:7890 tcp:7890
# adb reverse --list
## Set the proxy in Waydroid to localhost
# sudo waydroid shell settings put global http_proxy 127.0.0.1:7890
# sudo waydroid shell settings put global https_proxy 127.0.0.1:7890


## Tips and tricks
## Enable Window integration with Desktop Window Manager
# waydroid prop set persist.waydroid.multi_windows true
# waydroid session stop
# waydroid session start

## Setting viewport dimensions
# waydroid prop set persist.waydroid.width 576
# waydroid prop set persist.waydroid.height 1024

## USB Controller Device
# waydroid prop set persist.waydroid.udev true
# waydroid prop set persist.waydroid.uevent true


## General tips
## Make sure your Waydroid package is up to date
## Make sure you have the latest Waydroid image by running
# waydroid upgrade

## Reset Waydroid: stop the waydroid-container.service, run
# sudo systemctl stop waydroid-container
# sudo waydroid init -f
# sudo waydroid init -s GAPPS

## and start the service again
# sudo systemctl restart waydroid-container

## You may also want to do little cleanup, run
# rm -rf /var/lib/waydroid /home/.waydroid
# rm -rf ~/waydroid ~/.share/waydroid ~/.local/share/applications/*aydroid* ~/.local/share/waydroid


## Builds
# - [Android builds for Waydroid](https://github.com/WayDroid-ATV/waydroid-builds)
