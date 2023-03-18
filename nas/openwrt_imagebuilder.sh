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
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

OS_INFO_WSL=$(uname -r)

# Using the Image Builder
# https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# https://expoli.tech/articles/2019/03/22/1564656237381.html
if [[ -x "$(command -v pacman)" ]]; then
    # Pre-requisite packages
    PackagesList=(
        @c-development
        @development-libs
        @development-tools
        base-devel
        build-essential
        gawk
        gettext
        git
        libncurses5-dev
        libncursesw5-dev
        libssl-dev
        libxslt
        ncurses
        ncurses-devel
        openssl
        openssl-devel
        python
        python3
        rsync
        unzip
        wget
        which
        xsltproc
        zlib
        zlib-devel
        zlib-static
        zlib1g-dev
    )
    for TargetPackage in "${PackagesList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
            sudo pacman --noconfirm -S "${TargetPackage}"
        fi
    done
fi

BUILDER_URL="https://downloads.openwrt.org/snapshots/targets/x86/64/openwrt-imagebuilder-x86-64.Linux-x86_64.tar.xz"
# BUILDER_URL="https://openwrt.cc/releases/targets/x86/64/openwrt-imagebuilder-x86-64.Linux-x86_64.tar.xz"

INSTALLER_DOWNLOAD_FILE="${WORKDIR}/openwrt-imagebuilder-x86-64.Linux-x86_64.tar.xz"

curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${BUILDER_URL}"
curl_download_status=$?

[[ ${curl_download_status} -gt 0 ]] && exit 1

tar -xJf "${INSTALLER_DOWNLOAD_FILE}" -C "${PWD}"

cd "${PWD}/openwrt-imagebuilder-x86-64.Linux-x86_64" || exit
make info

## Selecting profile
# The PROFILE variable specifies the target image to build
# Run `make info` to obtain a list of available profiles
# PROFILE=profile-name

## Selecting packages
# The PACKAGES variable allows to include and/or exclude packages in the firmware image.
# By default (empty PACKAGES variable) the Image Builder will create a minimal image 
# with device-specific kernel and drivers, uci, ssh, switch, firewall, ppp and ipv6 support.
# PACKAGES="pkg1 pkg2 pkg3 -pkg4 -pkg5 -pkg6"
# The list of currently installed packages on your device can be obtained with the following command:
# echo $(opkg list-installed | sed -e "s/\s.*$//")

## Custom packages
# If there is a custom package or ipk you would prefer to use create a `packages` directory 
# if one does does not exist and place your custom ipk within this directory.

# sed 's/^option check_signature/# option check_signature/' ./repositories.conf
# tee -a ./repositories.conf >/dev/null <<-'EOF'

# src/gz openwrt_core https://openwrt.cc/snapshots/targets/x86/64/packages
# src/gz openwrt_base https://openwrt.cc/snapshots/packages/x86_64/base
# src/gz openwrt_luci https://openwrt.cc/snapshots/packages/x86_64/luci
# src/gz openwrt_packages https://openwrt.cc/snapshots/packages/x86_64/packages
# src/gz openwrt_routing https://openwrt.cc/snapshots/packages/x86_64/routing
# src/gz openwrt_telephony https://openwrt.cc/snapshots/packages/x86_64/telephony
# EOF

## Custom files
# The FILES variable allows custom configuration files to be included in images built with Image Builder.
# This is especially useful if you need to change the network configuration from default before flashing, 
# or if you are preparing an image for mass-flashing many devices.
# FILES=files/
# The files/ directory is best in the imagebuilder root folder (where you issue the make command) 
# otherwise it is best to use an absolute (full) path.
# files/etc/config/network -> /etc/config/network

# It is strongly recommended to use uci-defaults to incrementally integrate only the required customization.
# This helps minimize conflicts with auto-generated settings which can change between versions.
# https://openwrt.org/docs/guide-developer/uci-defaults
# files/etc/uci-defaults/xx_customizations

# make image PROFILE=XXX PACKAGES="pkg1 pk2 -pkg3 -pkg4" FILES=files/

# PACKAGES="iptraf-ng tcpdump -kmod-i40e -kmod-i40evf"
PACKAGES=$(grep -v '^#' "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/nas/openwrt_packages.list" | tr '\n' ' ')

if check_os_wsl; then
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        make image PROFILE="generic" PACKAGES="${PACKAGES}" FILES=files/
else
    make image PROFILE="generic" PACKAGES="${PACKAGES}" FILES=files/
fi

# Cleaning up
make clean


cd "${CURRENT_DIR}" || exit
