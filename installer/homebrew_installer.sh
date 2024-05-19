#!/usr/bin/env bash

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

# Use proxy or mirror when some sites were blocked or low speed
[[ -z "${THE_WORLD_BLOCKED}" ]] && set_proxy_mirrors_env

# https://brew.sh/index_zh-cn
colorEcho "${BLUE}Installing ${FUCHSIA}homebrew${BLUE}..."

[[ -z "${OS_INFO_TYPE}" ]] && get_os_type

if [[ "${THE_WORLD_BLOCKED}" == "true" ]]; then
    [[ -z "${HOMEBREW_BREW_GIT_REMOTE}" ]] && HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
    [[ -z "${HOMEBREW_CORE_GIT_REMOTE}" ]] && HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
    [[ -z "${HOMEBREW_BOTTLE_DOMAIN}" ]] && HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
    [[ -z "${HOMEBREW_API_DOMAIN}" ]] && HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

    # cask
    [[ -z "${MIRROR_HOMEBREW_CASK}" ]] && MIRROR_HOMEBREW_CASK="https://mirrors.ustc.edu.cn/homebrew-cask.git"
    # [[ -z "${MIRROR_HOMEBREW_CASK_VERSIONS}" ]] && MIRROR_HOMEBREW_CASK_VERSIONS="https://mirrors.ustc.edu.cn/homebrew-cask-versions.git"
fi

## [Brew installation fails due to Ruby versioning?](https://unix.stackexchange.com/questions/694020/brew-installation-fails-due-to-ruby-versioning)
# rbenv install 2.6.10

case "${OS_INFO_TYPE}" in
    darwin | linux)
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        ;;
    *)
        colorEcho "${RED}Operating system does not support!"
        exit 0
        ;;
esac

# https://docs.brew.sh/Homebrew-on-Linux
if [[ "${OS_INFO_TYPE}" == "linux" && -s "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    # if ! grep -q 'brew shellenv' "$HOME/.zprofile" >/dev/null 2>&1; then
    #     echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> "$HOME/.zprofile"
    # fi

    if ! grep -q 'brew shellenv' "$HOME/.zshrc" >/dev/null 2>&1; then
        (echo -e '\n# homebrew'; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> "$HOME/.zshrc"
    fi

    # eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi

## offical
# cd "$(brew --repo)"
# git remote set-url origin https://github.com/Homebrew/brew.git

# cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
# git remote set-url origin https://github.com/Homebrew/homebrew-core

# cd "$(brew --repo)/Library/Taps/homebrew/homebrew-cask"
# git remote set-url origin https://github.com/Homebrew/homebrew-cask

# unset HOMEBREW_CORE_GIT_REMOTE
# brew tap --custom-remote --force-auto-update homebrew/core "https://github.com/Homebrew/homebrew-core"
# brew tap --custom-remote --force-auto-update homebrew/cask "https://github.com/Homebrew/homebrew-cask"
# brew tap --custom-remote --force-auto-update homebrew/cask-versions "https://github.com/Homebrew/homebrew-cask-versions"

## mirrors
if [[ "${THE_WORLD_BLOCKED}" == "true" && -x "$(command -v brew)" ]]; then
    HOMEBREW_VERSION=$(brew --version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    if version_lt "${HOMEBREW_VERSION}" "4.0.0"; then
        # cd "$(brew --repo)" && \
        #     git remote set-url origin "https://mirrors.ustc.edu.cn/brew.git"

        # cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core" && \
        #     git remote set-url origin "https://mirrors.ustc.edu.cn/homebrew-core.git"

        # cd "$(brew --repo)/Library/Taps/homebrew/homebrew-cask" && \
        #     git remote set-url origin "https://mirrors.ustc.edu.cn/homebrew-cask.git"

        brew tap --custom-remote --force-auto-update homebrew/core "${HOMEBREW_CORE_GIT_REMOTE}"
        brew tap --custom-remote --force-auto-update homebrew/cask "${MIRROR_HOMEBREW_CASK}"
        # brew tap --custom-remote --force-auto-update homebrew/cask-versions "${MIRROR_HOMEBREW_CASK_VERSIONS}"
    fi
fi

## How to force homebrew to install a local file?
## https://stackoverflow.com/questions/59017569/how-to-force-homebrew-to-install-a-local-file
# brew install -b <formula>
## If a package fails to download, look for the cached location name and the url to download
## Note 3 things from the response:
## Cache folder location: <Cacheed_folder>($HOME/.cache/Homebrew/downloads/<Cacheed_filename>)
## Cached filename: <Cacheed_filename>
## Download url: <Download_url>
## Manual download the package:
# wget "<Download_url>" -O "<Cacheed_folder>/<Cacheed_filename>"
## Run brew install again
# brew install -b <formula>
# brew --cache <formula>

cd "${CURRENT_DIR}" || exit
