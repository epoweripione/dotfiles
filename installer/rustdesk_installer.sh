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

# RustDesk: Open source virtual/remote desktop infrastructure for everyone!
# https://github.com/rustdesk/rustdesk
INSTALLER_APP_NAME="rustdesk"
INSTALLER_GITHUB_REPO="rustdesk/rustdesk"

INSTALLER_INSTALL_NAME="rustdesk"

## self-host relay server
## https://rustdesk.com/docs/en/self-host/install/
# docker image pull rustdesk/rustdesk-server
# docker run --name hbbs \
#     --net=host \
#     -p 21115:21115 -p 21116:21116 -p 21116:21116/udp -p 21118:21118 \
#     -v `pwd`:/root \
#     rustdesk/rustdesk-server hbbs -r <relay-server-ip[:port]>
# docker run --name hbbr \
#     --net=host \
#     -p 21117:21117 -p 21119:21119 \
#     -v `pwd`:/root rustdesk/rustdesk-server hbbr

if [[ -x "$(command -v pacman)" ]]; then
    # Pre-requisite packages
    PackagesList=(
        clang
        gcc
        cmake
        make
        pkg-config
        nasm
        yasm
        alsa-lib
        xdotool
        libxcb
        libxfixes
        pulseaudio
        gtk3
        vcpkg
    )
    for TargetPackage in "${PackagesList[@]}"; do
        if checkPackageNeedInstall "${TargetPackage}"; then
            colorEcho "${BLUE}  Installing ${FUCHSIA}${TargetPackage}${BLUE}..."
            sudo pacman --noconfirm -S "${TargetPackage}"
        fi
    done
fi

# rust
if [[ ! -x "$(command -v rustc)" ]]; then
    [[ -s "${MY_SHELL_SCRIPTS}/installer/cargo_rust_installer.sh" ]] && \
        source "${MY_SHELL_SCRIPTS}/installer/cargo_rust_installer.sh"
fi

# vcpkg
if [[ -z "${VCPKG_ROOT}" && -x "$(command -v vcpkg)" ]]; then
    [[ -z "${VCPKG_ROOT}" ]] && VCPKG_ROOT=$(dirname "$(readlink -f "$(command -v vcpkg)")")
    [[ -z "${VCPKG_DOWNLOADS}" && -d "/var/cache/vcpkg" ]] && VCPKG_DOWNLOADS="/var/cache/vcpkg"
    export VCPKG_ROOT
    export VCPKG_DOWNLOADS
elif [[ -z "${VCPKG_ROOT}" && -d "$HOME/vcpkg" ]]; then
    export VCPKG_ROOT="$HOME/vcpkg"
fi

if [[ -z "${VCPKG_ROOT}" ]]; then
    Git_Clone_Update_Branch "microsoft/vcpkg" "$HOME/vcpkg"
    if [[ -d "$HOME/vcpkg" ]]; then
        "$HOME/vcpkg/bootstrap-vcpkg.sh"
        export VCPKG_ROOT="$HOME/vcpkg"
        mkdir -p "$HOME/.cache/vcpkg/"
        export VCPKG_DOWNLOADS="$HOME/.cache/vcpkg/"
    fi
fi

if [[ "${VCPKG_ROOT}" == *"$HOME"* ]]; then
    if ! "${VCPKG_ROOT}/vcpkg" list 2>/dev/null | grep -q 'libvpx\|libyuv\|opus'; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}libvpx libyuv opus${BLUE}..."
        "${VCPKG_ROOT}/vcpkg" install libvpx libyuv opus
    fi
else
    if ! vcpkg list 2>/dev/null | grep -q 'libvpx\|libyuv\|opus'; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}libvpx libyuv opus${BLUE}..."
        sudo vcpkg install libvpx libyuv opus
    fi
fi

# Insall or Build
OS_RELEASE_ID="$(grep -E '^ID=([a-zA-Z]*)' /etc/os-release 2>/dev/null | cut -d '=' -f2)"
if [[ "${OS_RELEASE_ID}" == "manjaro" ]]; then
    if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
        INSTALLER_IS_UPDATE="yes"
        INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    else
        [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
    fi

    if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
        colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

        # INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases"
        # INSTALLER_VER_REMOTE=$(curl "${CURL_CHECK_OPTS[@]}" "${INSTALLER_CHECK_URL}" | jq -r 'map(select(.prerelease)) | first | .tag_name' | cut -d'v' -f2)

        if [[ -z "${INSTALLER_VER_REMOTE}" ]]; then
            INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
            App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
        fi
        if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
            INSTALLER_IS_INSTALL="no"
        fi
    fi

    if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

        INSTALLER_FILE_NAME="rustdesk-${INSTALLER_VER_REMOTE}-manjaro-arch.pkg.tar.zst"
        INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_FILE_NAME}"

        INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/${INSTALLER_GITHUB_REPO}/releases/download/${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"
        colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
        axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"

        curl_download_status=$?
        if [[ ${curl_download_status} -gt 0 && -n "${GITHUB_DOWNLOAD_URL}" ]]; then
            INSTALLER_DOWNLOAD_URL="${INSTALLER_DOWNLOAD_URL//${GITHUB_DOWNLOAD_URL}/https://github.com}"
            colorEcho "${BLUE}  From ${ORANGE}${INSTALLER_DOWNLOAD_URL}"
            axel "${AXEL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}" || curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${INSTALLER_DOWNLOAD_FILE}" "${INSTALLER_DOWNLOAD_URL}"
            curl_download_status=$?
        fi

        if [[ ${curl_download_status} -eq 0 ]]; then
            sudo pacman --noconfirm -U "${INSTALLER_DOWNLOAD_FILE}"
        fi

        # ignoring package upgrade with pacman or yay
        PacmanConf=$(yay -Pg 2>/dev/null | jq -r '.pacmanconf//empty')
        [[ -z "${PacmanConf}" ]] && PacmanConf="/etc/pacman.conf"
        if ! grep -q '^IgnorePkg.*' "${PacmanConf}"; then
            sudo sed -i '0,/^#\s*IgnorePkg/{s/^#\s*IgnorePkg.*/IgnorePkg=/}' "${PacmanConf}"
        fi

        if grep -q '^IgnorePkg.*' "${PacmanConf}"; then
            IgnorePkg=$(grep '^IgnorePkg' "${PacmanConf}" | cut -d"=" -f2)
            if [[ -z "${IgnorePkg}" ]]; then
                sudo sed -i "s/^IgnorePkg.*/IgnorePkg=rustdesk/" "${PacmanConf}"
            elif [[ "${IgnorePkg}" != *"rustdesk"* ]]; then
                sudo sed -i "s/^IgnorePkg.*/IgnorePkg=${IgnorePkg},rustdesk/" "${PacmanConf}"
            fi
        fi
    fi
else
    Git_Clone_Update_Branch "${INSTALLER_GITHUB_REPO}" "$HOME/rustdesk"
    if [[ -d "$HOME/rustdesk" ]]; then
        cd "$HOME/rustdesk" && \
            mkdir -p target/debug && \
            wget "https://raw.githubusercontent.com/c-smile/sciter-sdk/master/bin.lnx/x64/libsciter-gtk.so" && \
            mv libsciter-gtk.so target/debug && \
            sudo cp target/debug/libsciter-gtk.so /usr/lib && \
            cargo install --path .

            # cargo run
    fi
fi
