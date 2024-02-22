#!/usr/bin/env bash

# Load custom functions
if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh" ]]; then
    source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh"
else
    echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh does not exist!"
    exit 0
fi

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type
[[ -z "${OS_INFO_ARCH}" ]] && get_arch


if [[ -x "$(command -v pacman)" ]]; then
    PackagesList=(
        curl
        wget
    )
    InstallSystemPackages "" "${PackagesList[@]}"
fi

if [[ ! "$(command -v wget)" ]]; then
    colorEcho "${FUCHSIA}wget${RED} is not installed!"
    exit
fi

if [[ ! "$(command -v curl)" ]]; then
    colorEcho "${FUCHSIA}curl${RED} is not installed!"
    exit
fi


if [[ "${OS_INFO_TYPE}" == "windows" ]]; then
    colorEchoN "${ORANGE}Use proxy?[y/${CYAN}N${ORANGE}]: "
    read -r USE_PROXY

    if [[ "${OS_INFO_ARCH}" == "amd64" ]]; then
        ver="win64"
        url1="https://storage.googleapis.com/chromium-browser-snapshots/Win_x64"
        url2="https://storage.googleapis.com/chromium-browser-snapshots/win_rel"
    else
        ver="win32"
        url1="https://storage.googleapis.com/chromium-browser-snapshots/Win"
        url2="https://storage.googleapis.com/chromium-browser-snapshots/win32_rel"
    fi

    if [[ "$USE_PROXY" == 'y' || "$USE_PROXY" == 'Y' ]]; then
        chromium_ver1=$(curl -fsSL --socks5-hostname 127.0.0.1:55880 "${url1}/LAST_CHANGE")
        chromium_ver2=$(curl -fsSL --socks5-hostname 127.0.0.1:55880 "${url2}/LAST_CHANGE")
    else
        chromium_ver1=$(curl -fsSL "${url1}/LAST_CHANGE")
        chromium_ver2=$(curl -fsSL "${url2}/LAST_CHANGE")
    fi

    if [[ $chromium_ver1 -gt $chromium_ver2 ]]; then
        url=$url1
        chromium_ver=$chromium_ver1
    else
        url=$url2
        chromium_ver=$chromium_ver2
    fi

    if [[ -d "/d/Downloads" ]]; then
        echo "Downloading Chromium Dev ${OS_INFO_TYPE}-${OS_INFO_ARCH}-r$chromium_ver"
        if [[ "$USE_PROXY" == 'y' || "$USE_PROXY" == 'Y' ]]; then
            wget -e "http_proxy=http://127.0.0.1:55881" -e "https_proxy=http://127.0.0.1:55881" \
                -O "/d/Downloads/chrome-$ver-$chromium_ver.zip" \
                -c "${url}/${chromium_ver}/chrome-win.zip"
        else
            wget -O "/d/Downloads/chrome-$ver-$chromium_ver.zip" \
                -c "${url}/${chromium_ver}/chrome-win.zip"
        fi

        # if [[ "$USE_PROXY" == 'y' || "$USE_PROXY" == 'Y' ]]; then
        #     curl --socks5-hostname 127.0.0.1:55880 -fSL \
        #         -o "/d/Downloads/chrome-$ver-$chromium_ver.zip" \
        #         -C - "${url}/${chromium_ver}/chrome-win.zip"
        # else
        #     curl -fSL \
        #         -o "/d/Downloads/chrome-$ver-$chromium_ver.zip" \
        #         -C - "${url}/${chromium_ver}/chrome-win.zip"
        # fi
    fi
fi
