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


# git-flow (AVH Edition)
# https://github.com/petervanderdoes/gitflow-avh
if [[ ! "$(command -v git-flow)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}git-flow (AVH Edition)${BLUE}..."
    DOWNLOAD_URL="https://raw.githubusercontent.com/petervanderdoes/gitflow-avh/develop/contrib/gitflow-installer.sh"
    wget -O "${WORKDIR}/gitflow-installer.sh" "${DOWNLOAD_URL}" && \
        cd "/usr/local" && \
        sudo bash "${WORKDIR}/gitflow-installer.sh" install develop
fi

## How to use
# http://danielkummer.github.io/git-flow-cheatsheet/index.zh_CN.html
# https://github.com/mylxsw/growing-up/blob/master/doc/%E7%A0%94%E5%8F%91%E5%9B%A2%E9%98%9FGIT%E5%BC%80%E5%8F%91%E6%B5%81%E7%A8%8B%E6%96%B0%E4%BA%BA%E5%AD%A6%E4%B9%A0%E6%8C%87%E5%8D%97.md


## gitmoji-cli: A gitmoji interactive command line tool for using emojis on commits
# https://github.com/carloscuesta/gitmoji-cli
# Usage:
# gitmoji --help
if [[ "$(command -v node)" ]]; then
    npm install -g gitmoji-cli
fi

cd "${CURRENT_DIR}" || exit