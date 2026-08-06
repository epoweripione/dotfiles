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

# [Cloudflare WARP packages](https://pkg.cloudflareclient.com/)

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

function installCloudflareWarp() {
    # Install WireGuard tools and module
    if [[ ${OS} == 'ubuntu' ]] || [[ ${OS} == 'debian' ]]; then
        curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list

        sudo apt-get update
        sudo apt-get install -y cloudflare-warp
    elif [[ ${OS} == 'fedora' ]] || [[ ${OS} == 'centos' ]] || [[ ${OS} == 'almalinux' ]] || [[ ${OS} == 'rocky' ]]; then
        curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo
        sudo dnf update -y
        sudo dnf install -y cloudflare-warp
    else
        colorEcho "${RED}Cloudflare WARP installation is not supported on this OS: ${OS}"
        exit 1
    fi

    # Verify installation
    if ! command -v warp-cli &>/dev/null; then
        colorEcho "${RED}Cloudflare WARP installation failed. The 'warp-cli' command was not found."
        colorEcho "${RED}Please check the installation output above for errors."
        exit 1
    fi
}

function initialCheck() {
    checkOS
}

if [[ -x "$(command -v warp-cli)" ]]; then
    colorEcho "${GREEN}Cloudflare WARP is already installed."
else
    initialCheck
    installCloudflareWarp
fi

: '
# Usage
# /var/lib/cloudflare-warp
warp-cli --accept-tos registration new
warp-cli account
warp-cli mode proxy
warp-cli proxy port 40000
warp-cli connect
warp-cli status
warp-cli disconnect

# transfer wgcf license key
warp-cli set-license <wgcf-license-key>
warp-cli account
'
