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


## Enable systemd-networkd in host
## https://wiki.archlinux.org/title/Systemd-networkd
## ls /etc/systemd/network/
## journalctl --boot=0 --unit=systemd-networkd
# [[ $(systemctl is-enabled network 2>/dev/null) ]] && sudo systemctl disable network && sudo systemctl stop network
# [[ $(systemctl is-enabled networking 2>/dev/null) ]] && sudo systemctl disable networking && sudo systemctl stop networking
# [[ $(systemctl is-enabled NetworkManager 2>/dev/null) ]] && sudo systemctl disable NetworkManager && sudo systemctl stop NetworkManager

# [[ -s "/etc/network/interfaces" ]] && sudo mv "/etc/network/interfaces" "/etc/network/interfaces.save"

colorEcho "${BLUE}Enabling ${FUCHSIA}systemd-netwrokd & systemd-resolved${BLUE}..."
sudo systemctl enable systemd-networkd && sudo systemctl start systemd-networkd
sudo systemctl enable systemd-resolved && sudo systemctl start systemd-resolved
# sudo ln -sf "/run/systemd/resolve/resolv.conf" "/etc/resolv.conf"


## Setting a static IP for default network interface
# [[ -z "${NETWORK_INTERFACE_DEFAULT}" ]] && get_network_interface_default
# sudo tee "/etc/systemd/network/20-wired-${NETWORK_INTERFACE_DEFAULT}.network" >/dev/null <<-EOF
# [Match]
# Name=${NETWORK_INTERFACE_DEFAULT}
#
# [Network]
# #DHCP=yes
# Address=192.168.1.100/24
# Gateway=192.168.1.1
# # DNS=1.1.1.1
# # DNS=8.8.8.8
# EOF
# sudo systemctl restart systemd-networkd

## resolvectl status
# sudo tee "/etc/resolv.conf" >/dev/null <<-'EOF'
# nameserver 114.114.114.114
# nameserver 1.1.1.1
# nameserver 8.8.8.8
# EOF
# sudo systemctl restart systemd-resolved


# SmartDNS
if [[ "${IP_GEO_IN_CHINA}" == "yes" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/smartdns_insaller.sh" ]] && \
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/smartdns_insaller.sh"
fi


# Samba
[[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/samba_setup.sh" ]] && \
    source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/manjaro/samba_setup.sh"


cd "${CURRENT_DIR}" || exit
