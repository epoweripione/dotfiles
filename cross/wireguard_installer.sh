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

App_Installer_Reset

# [WireGuard is a simple yet fast and modern VPN that utilizes state-of-the-art cryptography](https://www.wireguard.com/)

## Install script
## [WireGuard](https://github.com/hwdsl2/wireguard-install)
# wget -O wireguard.sh https://get.vpnsetup.net/wg
# sudo bash wireguard.sh --auto

## [OpenVPN](https://github.com/hwdsl2/openvpn-install)
# wget -O openvpn.sh https://get.vpnsetup.net/ovpn
# sudo bash openvpn.sh --auto

## [IPsec VPN](https://github.com/hwdsl2/setup-ipsec-vpn)
# wget https://get.vpnsetup.net -O vpn.sh && sudo sh vpn.sh

## [Headscale](https://github.com/hwdsl2/headscale-install)
# wget -O headscale.sh https://get.vpnsetup.net/hs
# sudo bash headscale.sh --auto --serverurl https://hs.example.com

## [WireGuard installer](https://github.com/angristan/wireguard-install)
# curl -O https://raw.githubusercontent.com/angristan/wireguard-install/master/wireguard-install.sh
# sudo bash wireguard-install.sh

function isRoot() {
    if [ "${EUID}" -ne 0 ]; then
        echo "You need to run this script as root"
        exit 1
    fi
}

function checkVirt() {
    if command -v virt-what &>/dev/null; then
        VIRT=$(virt-what)
    else
        VIRT=$(systemd-detect-virt)
    fi
    if [[ ${VIRT} == "openvz" ]]; then
        echo "OpenVZ is not supported"
        exit 1
    fi
    if [[ ${VIRT} == "lxc" ]]; then
        echo "LXC is not supported (yet)."
        echo "WireGuard can technically run in an LXC container,"
        echo "but the kernel module has to be installed on the host,"
        echo "the container has to be run with some specific parameters"
        echo "and only the tools need to be installed in the container."
        exit 1
    fi
}

function checkOS() {
    source /etc/os-release
    OS="${ID}"
    if [[ ${OS} == "debian" || ${OS} == "raspbian" ]]; then
        if [[ ${VERSION_ID} -lt 10 ]]; then
            echo "Your version of Debian (${VERSION_ID}) is not supported. Please use Debian 10 Buster or later"
            exit 1
        fi
        OS=debian # overwrite if raspbian
    elif [[ ${OS} == "ubuntu" ]]; then
        RELEASE_YEAR=$(echo "${VERSION_ID}" | cut -d'.' -f1)
        if [[ ${RELEASE_YEAR} -lt 18 ]]; then
            echo "Your version of Ubuntu (${VERSION_ID}) is not supported. Please use Ubuntu 18.04 or later"
            exit 1
        fi
    elif [[ ${OS} == "fedora" ]]; then
        if [[ ${VERSION_ID} -lt 32 ]]; then
            echo "Your version of Fedora (${VERSION_ID}) is not supported. Please use Fedora 32 or later"
            exit 1
        fi
    elif [[ ${OS} == 'centos' ]] || [[ ${OS} == 'almalinux' ]] || [[ ${OS} == 'rocky' ]]; then
        if [[ ${VERSION_ID} == 7* ]]; then
            echo "Your version of CentOS (${VERSION_ID}) is not supported. Please use CentOS 8 or later"
            exit 1
        fi
    elif [[ -e /etc/oracle-release ]]; then
        source /etc/os-release
        OS=oracle
    elif [[ -e /etc/arch-release ]]; then
        OS=arch
    elif [[ -e /etc/alpine-release ]]; then
        OS=alpine
        if ! command -v virt-what &>/dev/null; then
            if ! (apk update && apk add virt-what); then
                colorEcho "${RED}Failed to install virt-what. Continuing without virtualization check."
            fi
        fi
    else
        echo "Looks like you aren't running this installer on a Debian, Ubuntu, Fedora, CentOS, AlmaLinux, Oracle or Arch Linux system"
        exit 1
    fi
}

function installWireGuard() {
    # Install WireGuard tools and module
    if [[ ${OS} == 'ubuntu' ]] || [[ ${OS} == 'debian' && ${VERSION_ID} -gt 10 ]]; then
        sudo apt-get update
        sudo apt-get install -y wireguard iptables resolvconf qrencode
    elif [[ ${OS} == 'debian' ]]; then
        if ! grep -rqs "^deb .* buster-backports" /etc/apt/; then
            echo "deb http://deb.debian.org/debian buster-backports main" >/etc/apt/sources.list.d/backports.list
            sudo apt-get update
        fi
        sudo apt-get update
        sudo apt-get install -y iptables resolvconf qrencode
        sudo apt-get install -y -t buster-backports wireguard
    elif [[ ${OS} == 'fedora' ]]; then
        if [[ ${VERSION_ID} -lt 32 ]]; then
            sudo dnf install -y dnf-plugins-core
            sudo dnf copr enable -y jdoss/wireguard
            sudo dnf install -y wireguard-dkms
        fi
        sudo dnf install -y wireguard-tools iptables qrencode
    elif [[ ${OS} == 'centos' ]] || [[ ${OS} == 'almalinux' ]] || [[ ${OS} == 'rocky' ]]; then
        if [[ ${VERSION_ID} == 8* ]]; then
            sudo yum install -y epel-release elrepo-release
            sudo yum install -y kmod-wireguard
            sudo yum install -y qrencode || true # not available on release 9
        fi
        sudo yum install -y wireguard-tools iptables
    elif [[ ${OS} == 'oracle' ]]; then
        sudo dnf install -y oraclelinux-developer-release-el8
        sudo dnf config-manager --disable -y ol8_developer
        sudo dnf config-manager --enable -y ol8_developer_UEKR6
        sudo dnf config-manager --save -y --setopt=ol8_developer_UEKR6.includepkgs='wireguard-tools*'
        sudo dnf install -y wireguard-tools qrencode iptables
    elif [[ ${OS} == 'arch' ]]; then
        sudo pacman -S --needed --noconfirm wireguard-tools qrencode
    elif [[ ${OS} == 'alpine' ]]; then
        sudo apk update
        sudo apk add wireguard-tools iptables libqrencode-tools
    fi

    # Verify WireGuard installation
    if ! command -v wg &>/dev/null; then
        colorEcho "${RED}WireGuard installation failed. The 'wg' command was not found."
        echo "Please check the installation output above for errors."
        exit 1
    fi

    # Make sure the directory exists (this does not seem the be the case on fedora)
    sudo mkdir /etc/wireguard >/dev/null 2>&1
    sudo chmod 600 -R /etc/wireguard/
}

function initialCheck() {
    # isRoot
    checkOS
    checkVirt
}

# Check if WireGuard is already installed and load params
if [[ -x "$(command -v wg)" ]]; then
    colorEcho "${GREEN}WireGuard is already installed."
else
    initialCheck
    installWireGuard
fi

# systemctl status resolvconf
# resolvconf -l
