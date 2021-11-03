#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

## SuperBench.sh
## https://github.com/oooldking/script
# curl -fsSL https://raw.githubusercontent.com/oooldking/script/master/superbench.sh | bash


## LemonBench
# curl -fsSL https://github.com/LemonBench/LemonBench/raw/master/LemonBench.sh | bash -s fast
# curl -fsSL https://github.com/LemonBench/LemonBench/raw/master/LemonBench.sh | bash -s full


## bench.sh
## https://github.com/teddysun/across
# wget -qO- bench.sh | bash
# curl -Lso- bench.sh | bash
## or
# wget -qO- 86.re/bench.sh | bash
# curl -so- 86.re/bench.sh | bash


## Besttrack
# wget -qO- git.io/besttrace | bash
[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/besttrace" "https://github.com/zq/shell/raw/master/besttrace2021" && \
    sudo cp -f "${WORKDIR}/besttrace" "/usr/local/bin/besttrace" && \
    sudo chmod +x "/usr/local/bin/besttrace"

## China Telecom:
# besttrace -q1 gd.189.cn

## China Unicom:
# besttrace -q1 wo.cn

## China Mobile:
# besttrace -q1 gd.10086.cn


# UnixBench
# wget https://github.com/teddysun/across/raw/master/unixbench.sh && chmod +x unixbench.sh && ./unixbench.sh


cd "${CURRENT_DIR}" || exit